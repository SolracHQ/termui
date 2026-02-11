import ../core/widget
import ../core/[primitives, context, constraints]
import ../layout/size_specs
from std/terminal import Style
import illwill

export Style
export ForegroundColor, BackgroundColor

type TextBox* = ref object of Widget
  lines*: seq[string]
  style*: set[Style]
  fgColor*: ForegroundColor
  bgColor*: BackgroundColor

proc newTextBox*(
    lines: seq[string],
    width: SizeSpec = content(),
    height: SizeSpec = content(),
    style: set[Style] = {},
    fgColor: ForegroundColor = ForegroundColor.fgNone,
    bgColor: BackgroundColor = BackgroundColor.bgNone,
): TextBox =
  # Validate no newlines in individual lines
  for i, line in lines:
    if '\n' in line:
      raise newException(
        ValueError,
        "TextBox line " & $i & " contains newline character. Lines must not contain \\n.",
      )

  result = TextBox(lines: lines, style: style, fgColor: fgColor, bgColor: bgColor)

  result.constraints.width = width
  result.constraints.height = height

proc maxLineLength(lines: seq[string]): int =
  result = 0
  for line in lines:
    result = max(result, line.len)

method measure*(textbox: TextBox, available: Size): MeasureResult =
  result.min = Size(width: 1, height: 1)
  result.preferred =
    Size(width: textbox.lines.maxLineLength(), height: textbox.lines.len)

method arrange*(textbox: TextBox, rect: Rect): ArrangeResult =
  textbox.calculatedRect = rect

  if rect.size.width < 1 or rect.size.height < 1:
    return arClipped

  let maxWidth = textbox.lines.maxLineLength()
  let totalHeight = textbox.lines.len

  # Check if all content fits
  if maxWidth <= rect.size.width and totalHeight <= rect.size.height:
    return arSuccess
  else:
    return arClipped

proc applyStyle(textbox: TextBox, tb: var TerminalBuffer) =
  if textbox.fgColor != fgNone:
    tb.setForegroundColor(textbox.fgColor)
  if textbox.bgColor != bgNone:
    tb.setBackgroundColor(textbox.bgColor)
  if textbox.style.len > 0:
    tb.setStyle(textbox.style)

method render*(textbox: TextBox, ctx: var RenderContext) =
  let rect = textbox.calculatedRect

  textbox.applyStyle(ctx.tb)

  var y = rect.pos.y
  for line in textbox.lines:
    if y >= rect.pos.y + rect.size.height:
      break

    # Clip line to available width
    let displayText =
      if line.len > rect.size.width:
        line[0 ..< rect.size.width]
      else:
        line

    ctx.tb.write(rect.pos.x, y, displayText)
    inc y

  ctx.tb.resetAttributes()
