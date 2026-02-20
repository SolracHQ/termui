import ../core/widget
import ../core/[primitives, context, constraints]
from std/terminal import Style
import term

export Style
export ForegroundColor, BackgroundColor

type TextBox* = ref object of SizedWidget
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
  result.preferred = Size(
    width: textbox.lines.maxLineLength().Natural, height: textbox.lines.len.Natural
  )

method arrange*(textbox: TextBox, rect: Rect): ArrangeResult =
  textbox.calculatedRect = rect

  if rect.size.width < 1 or rect.size.height < 1:
    return arClipped

  let maxWidth = textbox.lines.maxLineLength().Natural
  let totalHeight = textbox.lines.len.Natural

  # Check if all content fits
  if maxWidth <= rect.size.width and totalHeight <= rect.size.height:
    return arSuccess
  else:
    return arClipped

proc applyStyle(textbox: TextBox, ts: TerminalSlice) =
  if textbox.fgColor != fgNone:
    ts.setForegroundColor(textbox.fgColor)
  if textbox.bgColor != bgNone:
    ts.setBackgroundColor(textbox.bgColor)
  if textbox.style.len > 0:
    ts.setStyle(textbox.style)

method render*(textbox: TextBox, ctx: var RenderContext) =
  let rect = textbox.calculatedRect

  textbox.applyStyle(ctx.slice)

  var y = 0
  for line in textbox.lines:
    if y >= rect.size.height:
      break

    # Clip line to available width
    let displayText =
      if line.len.Natural > rect.size.width:
        line[0 ..< rect.size.width]
      else:
        line

    ctx.slice.write(0, y, displayText)
    inc y

  ctx.slice.resetAttributes()
