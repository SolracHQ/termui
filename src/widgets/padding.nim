import ../core/widget
import ../core/[primitives, context, constraints]
import ../layout/size_specs
import vbox

type Padding* = ref object of VBox
  ## Padding widget that adds space around children (acts like VBox with padding)
  left*: int
  right*: int
  top*: int
  bottom*: int

proc newPadding*(
    children: seq[Widget] = @[],
    width: SizeSpec = content(),
    height: SizeSpec = content(),
    left: int = 0,
    right: int = 0,
    top: int = 0,
    bottom: int = 0,
    spacing: int = 0,
    alignment: Alignment = alStart,
): Padding =
  ## Create a new padding widget with specified padding on each side
  result = Padding(
    children: children,
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    spacing: spacing,
    alignment: alignment,
  )
  result.constraints.width = width
  result.constraints.height = height

proc config*(padding: var Padding, width: SizeSpec, height: SizeSpec, alignment: Alignment, spacing: int, left: int, right: int, top: int, bottom: int) =
  ## Configure an existing Padding instance
  padding.constraints.width = width
  padding.constraints.height = height
  padding.alignment = alignment
  padding.spacing = spacing
  padding.left = left
  padding.right = right
  padding.top = top
  padding.bottom = bottom

proc newPadding*(
    children: seq[Widget] = @[],
    width: SizeSpec = content(),
    height: SizeSpec = content(),
    padding: int = 0,
    spacing: int = 0,
    alignment: Alignment = alStart,
): Padding =
  ## Create a new padding widget with uniform padding on all sides
  newPadding(
    children, width, height, padding, padding, padding, padding, spacing, alignment
  )

method measure*(padding: Padding, available: Size): MeasureResult =
  ## Measure the padding by measuring children like VBox and adding padding space
  let horizontalPadding = padding.left + padding.right
  let verticalPadding = padding.top + padding.bottom

  # Reduce available space by padding
  let childAvailable = Size(
    width: max(0, available.width - horizontalPadding),
    height: max(0, available.height - verticalPadding),
  )

  # Use VBox's measure logic
  let vboxMeasure = procCall VBox(padding).measure(childAvailable)

  result.min = Size(
    width: vboxMeasure.min.width + horizontalPadding,
    height: vboxMeasure.min.height + verticalPadding,
  )
  result.preferred = Size(
    width: vboxMeasure.preferred.width + horizontalPadding,
    height: vboxMeasure.preferred.height + verticalPadding,
  )

method arrange*(padding: Padding, rect: Rect): ArrangeResult =
  ## Arrange children within the padded area using VBox logic
  padding.calculatedRect = rect

  let horizontalPadding = padding.left + padding.right
  let verticalPadding = padding.top + padding.bottom

  # Calculate inner rect with padding applied
  let innerRect = Rect(
    pos: Position(x: rect.pos.x + padding.left, y: rect.pos.y + padding.top),
    size: Size(
      width: max(0, rect.size.width - horizontalPadding),
      height: max(0, rect.size.height - verticalPadding),
    ),
  )

  # Use VBox's arrange logic on the inner rect
  return procCall VBox(padding).arrange(innerRect)

method render*(padding: Padding, ctx: var RenderContext) =
  ## Render children using VBox logic
  procCall VBox(padding).render(ctx)
