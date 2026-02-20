import ../core/widget
import ../core/[primitives, context, constraints]
from std/terminal import Style
import std/hashes
import term

export Style
export ForegroundColor, BackgroundColor

type RectWidget* = ref object of Widget ## A simple colored rectangle widget
  bgColor*: BackgroundColor
  fgColor*: ForegroundColor
  fillChar*: char

proc newRect*(
    width: SizeSpec = fill(),
    height: SizeSpec = fill(),
    bgColor: BackgroundColor = BackgroundColor.bgNone,
    fgColor: ForegroundColor = ForegroundColor.fgNone,
    fillChar: char = ' ',
): RectWidget =
  result = RectWidget(bgColor: bgColor, fgColor: fgColor, fillChar: fillChar)
  result.constraints.width = width
  result.constraints.height = height

method measure*(rect: RectWidget, available: Size): MeasureResult =
  result.min = Size(width: 1, height: 1)
  result.preferred = Size(width: 1, height: 1)

method arrange*(rect: RectWidget, rect_area: Rect): ArrangeResult =
  rect.calculatedRect = rect_area

  if rect_area.size.width < 1 or rect_area.size.height < 1:
    return arClipped

  return arSuccess

method render*(rect: RectWidget, ctx: var RenderContext) =
  let area = rect(0, 0, rect.calculatedRect.size.width, rect.calculatedRect.size.height)

  if rect.bgColor != bgNone:
    ctx.slice.setBackgroundColor(rect.bgColor)
  if rect.fgColor != fgNone:
    ctx.slice.setForegroundColor(rect.fgColor)

  # Fill the rectangle with the fill character
  ctx.slice.fill(area, $rect.fillChar)

  ctx.slice.resetAttributes()

method hash*(rect: RectWidget): Hash =
  result = hash(rect.bgColor) xor hash(rect.fgColor) xor hash(rect.fillChar)
