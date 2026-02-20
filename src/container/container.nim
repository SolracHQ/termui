import ../core/primitives
import ../core/widget
import ../core/context
import ../core/constraints
import ../core/event
import ../term/output/slice
import ../term/output/box
import modifier

import std/hashes
import std/options

type
  Direction* = enum
    drHorizontal
    drVertical

  Container* = ref object of Widget
    children*: seq[Widget]
    modifier*: Modifier
    direction*: Direction

proc newContainer*(
    children: seq[Widget] = @[],
    modifier: Modifier = Modifier(),
    direction: Direction = drVertical,
): Container =
  result = Container(children: children, modifier: modifier, direction: direction)

method constraints*(c: Container): var WidgetConstraints =
  result = c.modifier.constraints

method measure*(c: Container, available: Size): MeasureResult =
  # Calculate space taken by modifiers
  let borderSpace = c.modifier.borderSize
  let paddingH = c.modifier.padding.horizontal
  let paddingV = c.modifier.padding.vertical

  var availableSize = Size(
    width: available.width - borderSpace - paddingH,
    height: available.height - borderSpace - paddingV,
  )

  # Measure children based on direction
  var totalMin, totalPref, maxMin, maxPref: Natural
  let totalSpacing = max(0, c.children.len - 1).Natural * c.modifier.spacing

  for child in c.children:
    let childMeasure = child.measure(availableSize)

    if c.direction == drVertical:
      totalMin += childMeasure.min.height
      totalPref += childMeasure.preferred.height
      maxMin = max(maxMin, childMeasure.min.width)
      maxPref = max(maxPref, childMeasure.preferred.width)
    else:
      totalMin += childMeasure.min.width
      totalPref += childMeasure.preferred.width
      maxMin = max(maxMin, childMeasure.min.height)
      maxPref = max(maxPref, childMeasure.preferred.height)

  if c.direction == drVertical:
    result.min = Size(
      width: maxMin + paddingH + borderSpace,
      height: totalMin + totalSpacing + paddingV + borderSpace,
    )
    result.preferred = Size(
      width: maxPref + paddingH + borderSpace,
      height: totalPref + totalSpacing + paddingV + borderSpace,
    )
  else:
    result.min = Size(
      width: totalMin + totalSpacing + paddingH + borderSpace,
      height: maxMin + paddingV + borderSpace,
    )
    result.preferred = Size(
      width: totalPref + totalSpacing + paddingH + borderSpace,
      height: maxPref + paddingV + borderSpace,
    )

method arrange*(c: Container, rect: Rect): ArrangeResult =
  c.calculatedRect = rect

  if c.children.len == 0:
    return arSuccess

  result = arSuccess

  # Apply modifiers to get inner rect
  var innerRect = rect

  if c.modifier.hasBorder:
    innerRect.pos.x += 1
    innerRect.pos.y += 1
    innerRect.size.width = innerRect.size.width - 2
    innerRect.size.height = innerRect.size.height - 2

  innerRect.pos.x += c.modifier.padding.left
  innerRect.pos.y += c.modifier.padding.top
  innerRect.size.width = innerRect.size.width - c.modifier.padding.horizontal
  innerRect.size.height = innerRect.size.height - c.modifier.padding.vertical

  # First pass: measure children and separate flex from non-flex
  var childWidths = newSeq[Natural](c.children.len)
  var childHeights = newSeq[Natural](c.children.len)
  var flexChildren: seq[int] = @[]
  var totalFlexFactor = 0.Natural
  var usedSpace = 0.Natural

  let totalSpacing = max(0, c.children.len - 1).Natural * c.modifier.spacing
  usedSpace += totalSpacing

  for i, child in c.children:
    let childMeasure = child.measure(innerRect.size)

    if c.direction == drVertical:
      # Vertical layout - flex affects height
      if child.constraints.height.isFlex():
        flexChildren.add(i)
        totalFlexFactor += child.constraints.height.getFlexFactor()
        childHeights[i] = 0
      else:
        childHeights[i] = child.constraints.height.resolve(
          innerRect.size.height, childMeasure.preferred.height
        )
        usedSpace += childHeights[i]

      # Width resolution
      childWidths[i] =
        if child.constraints.width.isFlex():
          childMeasure.preferred.width
        else:
          child.constraints.width.resolve(
            innerRect.size.width, childMeasure.preferred.width
          )
    else:
      # Horizontal layout - flex affects width
      if child.constraints.width.isFlex():
        flexChildren.add(i)
        totalFlexFactor += child.constraints.width.getFlexFactor()
        childWidths[i] = 0
      else:
        childWidths[i] = child.constraints.width.resolve(
          innerRect.size.width, childMeasure.preferred.width
        )
        usedSpace += childWidths[i]

      # Height resolution
      childHeights[i] =
        if child.constraints.height.isFlex():
          childMeasure.preferred.height
        else:
          child.constraints.height.resolve(
            innerRect.size.height, childMeasure.preferred.height
          )

  # Second pass: distribute remaining space to flex children
  let remainingSpace =
    if c.direction == drVertical:
      innerRect.size.height - usedSpace
    else:
      innerRect.size.width - usedSpace

  if flexChildren.len > 0 and totalFlexFactor > 0:
    for childIdx in flexChildren:
      let child = c.children[childIdx]

      if c.direction == drVertical:
        childHeights[childIdx] =
          child.constraints.height.resolveFlex(remainingSpace, totalFlexFactor)
      else:
        childWidths[childIdx] =
          child.constraints.width.resolveFlex(remainingSpace, totalFlexFactor)

  # Third pass: arrange children
  var currentX = innerRect.pos.x
  var currentY = innerRect.pos.y

  for i, child in c.children:
    let childWidth = childWidths[i]
    let childHeight = childHeights[i]

    var childX, childY: Natural

    if c.direction == drVertical:
      # Vertical: Y advances, X depends on alignment
      childY = currentY
      childX =
        case c.modifier.alignment
        of alStart:
          innerRect.pos.x
        of alCenter:
          innerRect.pos.x + (innerRect.size.width - childWidth) div 2
        of alEnd:
          innerRect.pos.x + innerRect.size.width - childWidth
        of alStretch:
          innerRect.pos.x
    else:
      # Horizontal: X advances, Y depends on alignment
      childX = currentX
      childY =
        case c.modifier.alignment
        of alStart:
          innerRect.pos.y
        of alCenter:
          innerRect.pos.y + (innerRect.size.height - childHeight) div 2
        of alEnd:
          innerRect.pos.y + innerRect.size.height - childHeight
        of alStretch:
          innerRect.pos.y

    let childRect = Rect(
      pos: Position(x: childX, y: childY),
      size: Size(width: childWidth, height: childHeight),
    )

    let childResult = child.arrange(childRect)

    # Track if any child was clipped or too small
    if childResult == arClipped:
      result = arClipped
    elif childResult == arTooSmall and result != arClipped:
      result = arTooSmall

    # Advance position
    if c.direction == drVertical:
      currentY += childHeight + c.modifier.spacing
    else:
      currentX += childWidth + c.modifier.spacing

  # Check if we exceeded bounds
  if c.direction == drVertical:
    if currentY - c.modifier.spacing > innerRect.pos.y + innerRect.size.height:
      if result == arSuccess:
        result = arClipped
  else:
    if currentX - c.modifier.spacing > innerRect.pos.x + innerRect.size.width:
      if result == arSuccess:
        result = arClipped

method render*(c: Container, ctx: var RenderContext) =
  # Render border if present
  if c.modifier.hasBorder:
    let w = ctx.slice.width()
    let h = ctx.slice.height()
    ctx.slice.drawRect(0, 0, w - 1, h - 1, c.modifier.doubleStyle)

  # Render background if present
  if c.modifier.hasBackground:
    let w = ctx.slice.width()
    let h = ctx.slice.height()
    let prev = ctx.slice.getBackgroundColor()
    ctx.slice.setBackgroundColor(c.modifier.bgColor)

    let fillRect = rect(
      if c.modifier.hasBorder: 1 else: 0,
      if c.modifier.hasBorder: 1 else: 0,
      w - (if c.modifier.hasBorder: 2 else: 0),
      h - (if c.modifier.hasBorder: 2 else: 0),
    )
    ctx.slice.fill(fillRect, " ")
    ctx.slice.setBackgroundColor(prev)

  # Render children with their own slices
  for child in c.children:
    # Create slice directly from absolute rect using the root buffer
    let childSlice = newSlice(ctx.slice.tb, child.calculatedRect)
    var childCtx = RenderContext(slice: childSlice)
    child.render(childCtx)

method onEvent*(w: Container, e: Event): bool =
  # Try on childs first
  for child in w.children:
    let pos = e.pos
    if pos.isSome:
      if not child.calculatedRect.contains(pos.get):
        continue

    if child.onEvent(e):
      return true
  if not w.handler.isNil and w.handler(e):
    return true
  return false

method hash*(c: Container): int =
  return hash(c.children) !& hash(c.modifier) !& hash(c.direction)
