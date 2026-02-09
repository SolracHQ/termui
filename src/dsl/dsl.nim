import illwill
import ../widgets/hbox as widget_hbox
import ../widgets/vbox as widget_vbox
import ../widgets/label as widget_label
import ../widgets/padding as widget_padding
import ../widgets/rect as widget_rect
import ../widgets/textbox as widget_textbox
import ../layout/size_specs

template tui*(tui_body: untyped) =
  var containerStack: seq[Container] =
    @[
      Container(
        widget_vbox.newVBox(width = fill(), height = fill(), spacing = 0, alignment = alStart)
      )
    ]

  proc config(
      width {.inject.}: SizeSpec = containerStack[^1].constraints.width,
      height {.inject.}: SizeSpec = containerStack[^1].constraints.height,
      alignment {.inject.}: Alignment = containerStack[^1].alignment,
  ) {.inject.} =
    containerStack[^1].constraints.width = width
    containerStack[^1].constraints.height = height
    containerStack[^1].alignment = alignment

  template hbox(body: untyped) {.inject.} =
    block:
      var hboxWidget = widget_hbox.newHBox()
      containerStack[^1].children.add hboxWidget
      containerStack.add hboxWidget
      defer:
        discard containerStack.pop()

      proc config(
          width {.inject.}: SizeSpec = hboxWidget.constraints.width,
          height {.inject.}: SizeSpec = hboxWidget.constraints.height,
          alignment {.inject.}: Alignment = hboxWidget.alignment,
          spacing {.inject.}: int = hboxWidget.spacing,
      ) {.inject.} =
        widget_hbox.config(hboxWidget, width, height, alignment, spacing)

      body

  template vbox(body: untyped) {.inject.} =
    block:
      var vboxWidget = widget_vbox.newVBox()
      containerStack[^1].children.add vboxWidget
      containerStack.add vboxWidget
      defer:
        discard containerStack.pop()

      proc config(
          width {.inject.}: SizeSpec = vboxWidget.constraints.width,
          height {.inject.}: SizeSpec = vboxWidget.constraints.height,
          alignment {.inject.}: Alignment = vboxWidget.alignment,
          spacing {.inject.}: int = vboxWidget.spacing,
      ) {.inject.} =
        widget_vbox.config(vboxWidget, width, height, alignment, spacing)

      body

  template padding(body: untyped) {.inject.} =
    block:
      var paddingWidget = widget_padding.newPadding(padding = 0)
      containerStack[^1].children.add paddingWidget
      containerStack.add paddingWidget
      defer:
        discard containerStack.pop()

      proc config(
          width {.inject.}: SizeSpec = paddingWidget.constraints.width,
          height {.inject.}: SizeSpec = paddingWidget.constraints.height,
          alignment {.inject.}: Alignment = paddingWidget.alignment,
          spacing {.inject.}: int = paddingWidget.spacing,
          left {.inject.}: int = paddingWidget.left,
          right {.inject.}: int = paddingWidget.right,
          top {.inject.}: int = paddingWidget.top,
          bottom {.inject.}: int = paddingWidget.bottom,
      ) {.inject.} =
        widget_padding.config(
          paddingWidget, width, height, alignment, spacing, left, right, top, bottom
        )

      body

  template label(text: string, body: untyped) {.inject.} =
    block:
      var labelWidget = widget_label.newLabel(text)
      containerStack[^1].children.add labelWidget

      proc config(
          width {.inject.}: SizeSpec = labelWidget.constraints.width,
          height {.inject.}: SizeSpec = labelWidget.constraints.height,
          overflowStrategy {.inject.}: OverflowStrategy = labelWidget.overflowStrategy,
          style {.inject.}: set[Style] = labelWidget.style,
          fgColor {.inject.}: ForegroundColor = labelWidget.fgColor,
          bgColor {.inject.}: BackgroundColor = labelWidget.bgColor,
      ) {.inject.} =
        widget_label.config(
          labelWidget, width, height, overflowStrategy, style, fgColor, bgColor
        )

      body

  template rect(body: untyped) {.inject.} =
    block:
      var rectWidget = widget_rect.newRect()
      containerStack[^1].children.add rectWidget

      proc config(
          width {.inject.}: SizeSpec = rectWidget.constraints.width,
          height {.inject.}: SizeSpec = rectWidget.constraints.height,
          bgColor {.inject.}: BackgroundColor = rectWidget.bgColor,
          fgColor {.inject.}: ForegroundColor = rectWidget.fgColor,
          fillChar {.inject.}: char = rectWidget.fillChar,
      ) {.inject.} =
        widget_rect.config(rectWidget, width, height, bgColor, fgColor, fillChar)

      body

  template textbox(lines: seq[string], body: untyped) {.inject.} =
    block:
      var textboxWidget = widget_textbox.newTextBox(lines)
      containerStack[^1].children.add textboxWidget

      proc config(
          width {.inject.}: SizeSpec = textboxWidget.constraints.width,
          height {.inject.}: SizeSpec = textboxWidget.constraints.height,
          style {.inject.}: set[Style] = textboxWidget.style,
          fgColor {.inject.}: ForegroundColor = textboxWidget.fgColor,
          bgColor {.inject.}: BackgroundColor = textboxWidget.bgColor,
      ) {.inject.} =
        widget_textbox.config(textboxWidget, width, height, style, fgColor, bgColor)

      body

  tui_body

  let root = containerStack[0]
  var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

  let terminalRect = Rect(
    pos: Position(x: 0, y: 0),
    size: Size(width: terminalWidth(), height: terminalHeight()),
  )

  discard root.measure(terminalRect.size)
  discard root.arrange(terminalRect)

  var ctx = RenderContext(tb: tb, clipRect: terminalRect)
  root.render(ctx)

  tb.display()
