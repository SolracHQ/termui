import termui
import widgets
import layout

proc main() =
  tui:
    self.spacing = 1
    self.alignment = alCenter

    with newLabel(
      "Label, TextBox & HBox Demo - Press ESC or Q to exit", style = {styleBright}
    )

    with newHBox(
      width = content(), height = content(), spacing = 2, alignment = alCenter
    ):
      with newLabel(
        "Hello, World!", width = fixed(20), style = {styleBright}, fgColor = fgGreen
      )

      with newLabel(
        "This is a very long text that will definitely overflow",
        width = fixed(30),
        overflowStrategy = osEllipsis,
        fgColor = fgYellow,
      )

      with newLabel(
        "Ellipsis in the middle of long text",
        width = fixed(20),
        overflowStrategy = osEllipsisMid,
        fgColor = fgMagenta,
      )

    with newLabel("TextBox (multi-line):")

    with newTextBox(
      @[
        "This is a TextBox widget", "It handles multiple lines",
        "Each line is separate", "No \\n characters needed!",
      ],
      width = fixed(30),
      height = content(),
      fgColor = fgCyan,
    )

    onEvent e:
      if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
        quit()

when isMainModule:
  main()
