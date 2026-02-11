import ../core/widget
import ../core/[primitives, constraints, context]
import ../layout

type HBox* = ref object of Container
  ## Horizontal box layout widget that arranges children in a row
  spacing*: int ## Space between children in cells

proc newHBox*(
    children: seq[Widget] = @[],
    width: SizeSpec = content(),
    height: SizeSpec = content(),
    spacing: int = 0,
    alignment: Alignment = alStart,
): HBox =
  ## Create a new horizontal box layout
  result = HBox(children: children, spacing: spacing, alignment: alignment)
  result.constraints.width = width
  result.constraints.height = height

method measure*(hbox: HBox, available: Size): MeasureResult =
  ## Measure the HBox by measuring all children
  var totalMinWidth = 0
  var totalPrefWidth = 0
  var maxMinHeight = 0
  var maxPrefHeight = 0

  let totalSpacing = max(0, hbox.children.len - 1) * hbox.spacing

  for child in hbox.children:
    let childMeasure = child.measure(available)

    # For width: resolve the child's constraint to get its actual desired width
    # If it's flex, we can't know yet (need remaining space), so use preferred
    let childWidth =
      if child.constraints.width.isFlex():
        childMeasure.preferred.width # Flex size determined during arrange
      else:
        child.constraints.width.resolve(available.width, childMeasure.preferred.width)

    # For height: resolve the child's constraint
    let childHeight =
      if child.constraints.height.isFlex():
        childMeasure.preferred.height
      else:
        child.constraints.height.resolve(
          available.height, childMeasure.preferred.height
        )

    totalMinWidth += childMeasure.min.width
    totalPrefWidth += childWidth
    maxMinHeight = max(maxMinHeight, childMeasure.min.height)
    maxPrefHeight = max(maxPrefHeight, childHeight)

  result.min = Size(width: totalMinWidth + totalSpacing, height: maxMinHeight)
  result.preferred = Size(width: totalPrefWidth + totalSpacing, height: maxPrefHeight)

proc resolveChildHeight(child: Widget, available: int, contentHeight: int): int =
  ## Helper to resolve a child's height
  child.constraints.height.resolve(available, contentHeight)

method arrange*(hbox: HBox, rect: Rect): ArrangeResult =
  ## Arrange children horizontally within the given rectangle
  hbox.calculatedRect = rect

  if hbox.children.len == 0:
    return arSuccess

  result = arSuccess

  # First pass: measure children and separate flex from non-flex
  var childWidths = newSeq[int](hbox.children.len)
  var childHeights = newSeq[int](hbox.children.len)
  var flexChildren: seq[int] = @[]
  var totalFlexFactor = 0
  var usedWidth = 0

  let totalSpacing = max(0, hbox.children.len - 1) * hbox.spacing
  usedWidth += totalSpacing

  for i, child in hbox.children:
    let childMeasure = child.measure(rect.size)

    # Resolve width using the new method-based approach
    if child.constraints.width.isFlex():
      flexChildren.add(i)
      totalFlexFactor += child.constraints.width.getFlexFactor()
      childWidths[i] = 0
    else:
      childWidths[i] =
        child.constraints.width.resolve(rect.size.width, childMeasure.preferred.width)
      usedWidth += childWidths[i]

    # Resolve height
    childHeights[i] =
      resolveChildHeight(child, rect.size.height, childMeasure.preferred.height)

  # Second pass: distribute remaining space to flex children
  let remainingWidth = max(0, rect.size.width - usedWidth)

  if flexChildren.len > 0 and totalFlexFactor > 0:
    for childIdx in flexChildren:
      let child = hbox.children[childIdx]
      childWidths[childIdx] =
        child.constraints.width.resolveFlex(remainingWidth, totalFlexFactor)

  # Third pass: arrange children
  var currentX = rect.pos.x

  for i, child in hbox.children:
    let childWidth = childWidths[i]
    let childHeight = childHeights[i]

    # Calculate Y position based on alignment
    let childY =
      case hbox.alignment
      of alStart:
        rect.pos.y
      of alCenter:
        rect.pos.y + (rect.size.height - childHeight) div 2
      of alEnd:
        rect.pos.y + rect.size.height - childHeight
      of alStretch:
        rect.pos.y

    let childRect = Rect(
      pos: Position(x: currentX, y: childY),
      size: Size(width: childWidth, height: childHeight),
    )

    let childResult = child.arrange(childRect)

    # Track if any child was clipped or too small
    if childResult == arClipped:
      result = arClipped
    elif childResult == arTooSmall and result != arClipped:
      result = arTooSmall

    currentX += childWidth + hbox.spacing

  # Check if we exceeded bounds
  if currentX - hbox.spacing > rect.pos.x + rect.size.width:
    if result == arSuccess:
      result = arClipped

method render*(hbox: HBox, ctx: var RenderContext) =
  ## Render all children in order
  for child in hbox.children:
    child.render(ctx)
