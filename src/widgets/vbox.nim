import ../core/widget
import ../core/[primitives, constraints, context]
import ../layout/size_specs

type VBox* = ref object of Container
  ## Vertical box layout widget that arranges children in a column
  spacing*: int ## Space between children in rows

proc newVBox*(
    children: seq[Widget] = @[],
    width: SizeSpec = content(),
    height: SizeSpec = content(),
    spacing: int = 0,
    alignment: Alignment = alStart,
): VBox =
  ## Create a new vertical box layout
  result = VBox(children: children, spacing: spacing, alignment: alignment)
  result.constraints.width = width
  result.constraints.height = height

method measure*(vbox: VBox, available: Size): MeasureResult =
  ## Measure the VBox by measuring all children
  var totalMinHeight = 0
  var totalPrefHeight = 0
  var maxMinWidth = 0
  var maxPrefWidth = 0

  let totalSpacing = max(0, vbox.children.len - 1) * vbox.spacing

  for child in vbox.children:
    let childMeasure = child.measure(available)

    # For height: resolve the child's constraint to get its actual desired height
    # If it's flex, we can't know yet (need remaining space), so use preferred
    let childHeight =
      if child.constraints.height.isFlex():
        childMeasure.preferred.height # Flex size determined during arrange
      else:
        child.constraints.height.resolve(
          available.height, childMeasure.preferred.height
        )

    # For width: resolve the child's constraint
    let childWidth =
      if child.constraints.width.isFlex():
        childMeasure.preferred.width
      else:
        child.constraints.width.resolve(available.width, childMeasure.preferred.width)

    totalMinHeight += childMeasure.min.height
    totalPrefHeight += childHeight
    maxMinWidth = max(maxMinWidth, childMeasure.min.width)
    maxPrefWidth = max(maxPrefWidth, childWidth)

  result.min = Size(width: maxMinWidth, height: totalMinHeight + totalSpacing)
  result.preferred = Size(width: maxPrefWidth, height: totalPrefHeight + totalSpacing)

proc resolveChildWidth(child: Widget, available: int, contentWidth: int): int =
  ## Helper to resolve a child's width
  child.constraints.width.resolve(available, contentWidth)

method arrange*(vbox: VBox, rect: Rect): ArrangeResult =
  ## Arrange children vertically within the given rectangle
  vbox.calculatedRect = rect

  if vbox.children.len == 0:
    return arSuccess

  result = arSuccess

  # First pass: measure children and separate flex from non-flex
  var childWidths = newSeq[int](vbox.children.len)
  var childHeights = newSeq[int](vbox.children.len)
  var flexChildren: seq[int] = @[]
  var totalFlexFactor = 0
  var usedHeight = 0

  let totalSpacing = max(0, vbox.children.len - 1) * vbox.spacing
  usedHeight += totalSpacing

  for i, child in vbox.children:
    let childMeasure = child.measure(rect.size)

    # Resolve height using the method-based approach
    if child.constraints.height.isFlex():
      flexChildren.add(i)
      totalFlexFactor += child.constraints.height.getFlexFactor()
      childHeights[i] = 0
    else:
      childHeights[i] = child.constraints.height.resolve(
        rect.size.height, childMeasure.preferred.height
      )
      usedHeight += childHeights[i]

    # Resolve width
    childWidths[i] =
      resolveChildWidth(child, rect.size.width, childMeasure.preferred.width)

  # Second pass: distribute remaining space to flex children
  let remainingHeight = max(0, rect.size.height - usedHeight)

  if flexChildren.len > 0 and totalFlexFactor > 0:
    for childIdx in flexChildren:
      let child = vbox.children[childIdx]
      childHeights[childIdx] =
        child.constraints.height.resolveFlex(remainingHeight, totalFlexFactor)

  # Third pass: arrange children
  var currentY = rect.pos.y

  for i, child in vbox.children:
    let childWidth = childWidths[i]
    let childHeight = childHeights[i]

    # Calculate X position based on alignment
    let childX =
      case vbox.alignment
      of alStart:
        rect.pos.x
      of alCenter:
        rect.pos.x + (rect.size.width - childWidth) div 2
      of alEnd:
        rect.pos.x + rect.size.width - childWidth
      of alStretch:
        rect.pos.x

    let childRect = Rect(
      pos: Position(x: childX, y: currentY),
      size: Size(width: childWidth, height: childHeight),
    )

    let childResult = child.arrange(childRect)

    # Track if any child was clipped or too small
    if childResult == arClipped:
      result = arClipped
    elif childResult == arTooSmall and result != arClipped:
      result = arTooSmall

    currentY += childHeight + vbox.spacing

  # Check if we exceeded bounds
  if currentY - vbox.spacing > rect.pos.y + rect.size.height:
    if result == arSuccess:
      result = arClipped

method render*(vbox: VBox, ctx: var RenderContext) =
  ## Render all children in order
  for child in vbox.children:
    child.render(ctx)
