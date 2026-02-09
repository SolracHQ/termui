import termui
import illwill
import std/os

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc main() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()

  tui:
    config(alignment = alCenter)

    label "Colombian Flag":
      config(
        width = content(), height = content(), style = {styleBright}, fgColor = fgWhite
      )

    padding:
      config(width = fill(), height = flex(), left = 4, right = 4, top = 2, bottom = 2)

      rect:
        config(width = fill(), height = flex(2), bgColor = bgYellow)

      rect:
        config(width = fill(), height = flex(1), bgColor = bgBlue)

      rect:
        config(width = fill(), height = flex(1), bgColor = bgRed)

    label "Flex ratio 2:1:1 (Yellow:Blue:Red) - Press ESC or Q to exit":
      config(width = content(), height = content(), fgColor = fgWhite)

  var key = getKey()
  while key != Key.Escape and key != Key.Q:
    sleep(20)
    key = getKey()

  exitProc()

when isMainModule:
  main()
