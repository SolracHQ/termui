import ../core/widget
import ../core/[primitives, context, constraints]
import ../layout
from std/terminal import Style
import illwill

export Style
export ForegroundColor, BackgroundColor

type
  OverflowStrategy* = enum
    osClip # Cut off at boundary
    osEllipsis # Show "..." at end
    osEllipsisMid # Show "..." in middle
    osError # Report as arTooSmall

  Label* = ref object of Widget
    text*: string
    overflowStrategy*: OverflowStrategy
    style*: set[Style]
    fgColor*: ForegroundColor
    bgColor*: BackgroundColor

proc newLabel*(
    text: string,
    width: SizeSpec = content(),
    height: SizeSpec = fixed(1),
    overflowStrategy: OverflowStrategy = osClip,
    style: set[Style] = {},
    fgColor: ForegroundColor = fgWhite,
    bgColor: BackgroundColor = bgBlack,
): Label =
  if '\n' in text:
    raise newException(
      ValueError, "Label text cannot contain newlines. Use TextBox for multi-line text."
    )

  result = Label(
    text: text,
    overflowStrategy: overflowStrategy,
    style: style,
    fgColor: fgColor,
    bgColor: bgColor,
  )

  result.constraints.width = width
  result.constraints.height = height

method measure*(label: Label, available: Size): MeasureResult =
  result.min = Size(width: 1, height: 1)
  result.preferred = Size(width: label.text.len, height: 1)

method arrange*(label: Label, rect: Rect): ArrangeResult =
  label.calculatedRect = rect

  if rect.size.width < 1 or rect.size.height < 1:
    return if label.overflowStrategy == osError: arTooSmall else: arClipped

  # Check if text fits
  if label.text.len <= rect.size.width:
    return arSuccess

  # Handle overflow
  if label.overflowStrategy == osError:
    return arTooSmall
  else:
    return arClipped

proc applyStyle(label: Label, tb: var TerminalBuffer) =
  if label.fgColor != fgNone:
    tb.setForegroundColor(label.fgColor)
  if label.bgColor != bgNone:
    tb.setBackgroundColor(label.bgColor)
  if label.style.len > 0:
    tb.setStyle(label.style)

proc processText(text: string, width: int, strategy: OverflowStrategy): string =
  if text.len <= width:
    return text

  case strategy
  of osClip:
    text[0 ..< width]
  of osEllipsis:
    if width >= 3:
      text[0 ..< width - 3] & "..."
    else:
      text[0 ..< width]
  of osEllipsisMid:
    if width >= 5:
      let halfWidth = (width - 3) div 2
      let endStart = text.len - (width - 3 - halfWidth)
      text[0 ..< halfWidth] & "..." & text[endStart ..< text.len]
    else:
      text[0 ..< width]
  of osError:
    text[0 ..< width]

method render*(label: Label, ctx: var RenderContext) =
  let rect = label.calculatedRect

  if rect.size.height < 1:
    return

  label.applyStyle(ctx.tb)

  let displayText = processText(label.text, rect.size.width, label.overflowStrategy)
  ctx.tb.write(rect.pos.x, rect.pos.y, displayText)

  ctx.tb.resetAttributes()
