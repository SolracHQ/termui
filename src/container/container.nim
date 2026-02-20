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
    drStack

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

# ---------------------------------------------------------------------------
# Measure helpers
# ---------------------------------------------------------------------------

proc innerSize(available: Size, modifier: Modifier): Size =
  let borderSpace = modifier.borderSize
  let paddingH = modifier.padding.horizontal
  let paddingV = modifier.padding.vertical
  Size(
    width: available.width - borderSpace - paddingH,
    height: available.height - borderSpace - paddingV,
  )

proc outerSize(inner: Size, modifier: Modifier): Size =
  let borderSpace = modifier.borderSize
  let paddingH = modifier.padding.horizontal
  let paddingV = modifier.padding.vertical
  Size(
    width: inner.width + borderSpace + paddingH,
    height: inner.height + borderSpace + paddingV,
  )

proc measureLinear(c: Container, availableInner: Size): MeasureResult =
  ## Measure for drHorizontal and drVertical.
  var totalMin, totalPref, maxMin, maxPref: Natural
  let totalSpacing = max(0, c.children.len - 1).Natural * c.modifier.spacing

  for child in c.children:
    let m = child.measure(availableInner)
    if c.direction == drVertical:
      totalMin += m.min.height
      totalPref += m.preferred.height
      maxMin = max(maxMin, m.min.width)
      maxPref = max(maxPref, m.preferred.width)
    else:
      totalMin += m.min.width
      totalPref += m.preferred.width
      maxMin = max(maxMin, m.min.height)
      maxPref = max(maxPref, m.preferred.height)

  if c.direction == drVertical:
    result.min = Size(width: maxMin, height: totalMin + totalSpacing)
    result.preferred = Size(width: maxPref, height: totalPref + totalSpacing)
  else:
    result.min = Size(width: totalMin + totalSpacing, height: maxMin)
    result.preferred = Size(width: totalPref + totalSpacing, height: maxPref)

proc measureStack(c: Container, availableInner: Size): MeasureResult =
  ## Measure for drStack: each child gets full space, result is the max of all.
  for child in c.children:
    let m = child.measure(availableInner)
    result.min.width = max(result.min.width, m.min.width)
    result.min.height = max(result.min.height, m.min.height)
    result.preferred.width = max(result.preferred.width, m.preferred.width)
    result.preferred.height = max(result.preferred.height, m.preferred.height)

method measure*(c: Container, available: Size): MeasureResult =
  let availableInner = innerSize(available, c.modifier)

  let inner =
    if c.direction == drStack:
      c.measureStack(availableInner)
    else:
      c.measureLinear(availableInner)

  result.min = outerSize(inner.min, c.modifier)
  result.preferred = outerSize(inner.preferred, c.modifier)

# ---------------------------------------------------------------------------
# Arrange helpers
# ---------------------------------------------------------------------------

proc calcInnerRect(rect: Rect, modifier: Modifier): Rect =
  var r = rect
  if modifier.hasBorder:
    r.pos.x += 1
    r.pos.y += 1
    r.size.width -= 2
    r.size.height -= 2
  r.pos.x += modifier.padding.left
  r.pos.y += modifier.padding.top
  r.size.width -= modifier.padding.horizontal
  r.size.height -= modifier.padding.vertical
  r

proc resolveChildSizes(
    c: Container,
    innerRect: Rect,
    childWidths: var seq[Natural],
    childHeights: var seq[Natural],
    flexChildren: var seq[int],
    totalFlexFactor: var Natural,
    usedSpace: var Natural,
) =
  ## First pass: resolve fixed/content sizes and collect flex children.
  let totalSpacing = max(0, c.children.len - 1).Natural * c.modifier.spacing
  usedSpace += totalSpacing

  for i, child in c.children:
    let m = child.measure(innerRect.size)

    if c.direction == drVertical:
      if child.constraints.height.isFlex():
        flexChildren.add(i)
        totalFlexFactor += child.constraints.height.getFlexFactor()
        childHeights[i] = 0
      else:
        childHeights[i] =
          child.constraints.height.resolve(innerRect.size.height, m.preferred.height)
        usedSpace += childHeights[i]

      childWidths[i] =
        if child.constraints.width.isFlex():
          m.preferred.width
        else:
          child.constraints.width.resolve(innerRect.size.width, m.preferred.width)
    else:
      if child.constraints.width.isFlex():
        flexChildren.add(i)
        totalFlexFactor += child.constraints.width.getFlexFactor()
        childWidths[i] = 0
      else:
        childWidths[i] =
          child.constraints.width.resolve(innerRect.size.width, m.preferred.width)
        usedSpace += childWidths[i]

      childHeights[i] =
        if child.constraints.height.isFlex():
          m.preferred.height
        else:
          child.constraints.height.resolve(innerRect.size.height, m.preferred.height)

proc distributeFlexSpace(
    c: Container,
    innerRect: Rect,
    childWidths: var seq[Natural],
    childHeights: var seq[Natural],
    flexChildren: seq[int],
    totalFlexFactor: Natural,
    usedSpace: Natural,
) =
  ## Second pass: distribute remaining space among flex children.
  if flexChildren.len == 0 or totalFlexFactor == 0:
    return

  let remaining =
    if c.direction == drVertical:
      innerRect.size.height - usedSpace
    else:
      innerRect.size.width - usedSpace

  for idx in flexChildren:
    let child = c.children[idx]
    if c.direction == drVertical:
      childHeights[idx] =
        child.constraints.height.resolveFlex(remaining, totalFlexFactor)
    else:
      childWidths[idx] = child.constraints.width.resolveFlex(remaining, totalFlexFactor)

proc alignedPos(
    primary, cross, crossSize, childCross: Natural, alignment: Alignment
): Natural =
  ## Compute aligned position on the cross axis.
  case alignment
  of alStart, alStretch:
    cross
  of alCenter:
    cross + (crossSize - childCross) div 2
  of alEnd:
    cross + crossSize - childCross

proc placeChildren(
    c: Container, innerRect: Rect, childWidths: seq[Natural], childHeights: seq[Natural]
): ArrangeResult =
  ## Third pass: position children and recurse into arrange.
  result = arSuccess
  var currentX = innerRect.pos.x
  var currentY = innerRect.pos.y

  for i, child in c.children:
    let w = childWidths[i]
    let h = childHeights[i]

    let (childX, childY) =
      if c.direction == drVertical:
        (
          alignedPos(
            currentY, innerRect.pos.x, innerRect.size.width, w, c.modifier.alignment
          ),
          currentY,
        )
      else:
        (
          currentX,
          alignedPos(
            currentX, innerRect.pos.y, innerRect.size.height, h, c.modifier.alignment
          ),
        )

    let childResult = child.arrange(
      Rect(pos: Position(x: childX, y: childY), size: Size(width: w, height: h))
    )

    if childResult == arClipped:
      result = arClipped
    elif childResult == arTooSmall and result != arClipped:
      result = arTooSmall

    if c.direction == drVertical:
      currentY += h + c.modifier.spacing
    else:
      currentX += w + c.modifier.spacing

  # Check if we overflowed
  if c.direction == drVertical:
    if currentY - c.modifier.spacing > innerRect.pos.y + innerRect.size.height:
      if result == arSuccess:
        result = arClipped
  else:
    if currentX - c.modifier.spacing > innerRect.pos.x + innerRect.size.width:
      if result == arSuccess:
        result = arClipped

proc arrangeStack(c: Container, innerRect: Rect): ArrangeResult =
  ## Arrange for drStack: every child gets the full inner rect.
  result = arSuccess
  for child in c.children:
    let childResult = child.arrange(innerRect)
    if childResult == arClipped:
      result = arClipped
    elif childResult == arTooSmall and result != arClipped:
      result = arTooSmall

method arrange*(c: Container, rect: Rect): ArrangeResult =
  c.calculatedRect = rect

  if c.children.len == 0:
    return arSuccess

  let innerRect = calcInnerRect(rect, c.modifier)

  if c.direction == drStack:
    return c.arrangeStack(innerRect)

  var childWidths = newSeq[Natural](c.children.len)
  var childHeights = newSeq[Natural](c.children.len)
  var flexChildren: seq[int] = @[]
  var totalFlexFactor = 0.Natural
  var usedSpace = 0.Natural

  c.resolveChildSizes(
    innerRect, childWidths, childHeights, flexChildren, totalFlexFactor, usedSpace
  )
  c.distributeFlexSpace(
    innerRect, childWidths, childHeights, flexChildren, totalFlexFactor, usedSpace
  )
  c.placeChildren(innerRect, childWidths, childHeights)

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------

method render*(c: Container, ctx: var RenderContext) =
  if c.modifier.hasBorder:
    let w = ctx.slice.width()
    let h = ctx.slice.height()
    ctx.slice.drawRect(0, 0, w - 1, h - 1, c.modifier.doubleStyle)

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

  for child in c.children:
    let childSlice = newSlice(ctx.slice.tb, child.calculatedRect)
    var childCtx = RenderContext(slice: childSlice)
    child.render(childCtx)

# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

method onEvent*(w: Container, e: Event): bool =
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
  hash(c.children) !& hash(c.modifier) !& hash(c.direction)
