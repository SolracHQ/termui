import ../core/widget
import ../core/[primitives, context, constraints]
import ../layout/size_specs
from std/terminal import Style
import illwill

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

proc config*(
    rect: var RectWidget,
    width: SizeSpec,
    height: SizeSpec,
    bgColor: BackgroundColor,
    fgColor: ForegroundColor,
    fillChar: char,
) =
  ## Configure an existing RectWidget instance.
  rect.constraints.width = width
  rect.constraints.height = height
  rect.bgColor = bgColor
  rect.fgColor = fgColor
  rect.fillChar = fillChar

method measure*(rect: RectWidget, available: Size): MeasureResult =
  result.min = Size(width: 1, height: 1)
  result.preferred = Size(width: 10, height: 3)

method arrange*(rect: RectWidget, rect_area: Rect): ArrangeResult =
  rect.calculatedRect = rect_area

  if rect_area.size.width < 1 or rect_area.size.height < 1:
    return arClipped

  return arSuccess

method render*(rect: RectWidget, ctx: var RenderContext) =
  let area = rect.calculatedRect

  if rect.bgColor != bgNone:
    ctx.tb.setBackgroundColor(rect.bgColor)
  if rect.fgColor != fgNone:
    ctx.tb.setForegroundColor(rect.fgColor)

  # Fill the rectangle with the fill character
  for y in area.pos.y ..< area.pos.y + area.size.height:
    for x in area.pos.x ..< area.pos.x + area.size.width:
      ctx.tb.write(x, y, $rect.fillChar)

  ctx.tb.resetAttributes()
