import termui
import illwill
import std/os

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

import macros
expandMacros:
  proc main() =
    illwillInit(fullscreen = true)
    setControlCHook(exitProc)
    hideCursor()

    tui:
      label "Label, TextBox & HBox Demo - Press ESC or Q to exit":
        config(width = content(), style = {styleBright}, fgColor = fgWhite)

      hbox:
        config(width = content(), height = content(), spacing = 2, alignment = alStart)

        label "Hello, World!":
          config(width = fixed(20), style = {styleBright}, fgColor = fgGreen)

        label "This is a very long text that will definitely overflow":
          config(width = fixed(30), overflowStrategy = osEllipsis, fgColor = fgYellow)

        label "Ellipsis in the middle of long text":
          config(
            width = fixed(20), overflowStrategy = osEllipsisMid, fgColor = fgMagenta
          )

      label "TextBox (multi-line):":
        config(width = content(), fgColor = fgWhite)

      textbox @[
        "This is a TextBox widget", "It handles multiple lines",
        "Each line is separate", "No \\n characters needed!",
      ]:
        config(width = fixed(30), height = content(), fgColor = fgCyan)

    var key = getKey()
    while key != Key.Escape and key != Key.Q:
      sleep(20)
      key = getKey()

    exitProc()

when isMainModule:
  main()
