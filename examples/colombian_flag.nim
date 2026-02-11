import termui
import illwill
import std/os

import widgets/[label, vbox, rect, padding]
import layout/size_specs

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc main() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()

  tui:
    self.alignment = alCenter
    with newLabel("Colombian Flag", style = {styleBright})

    with newPadding(
      width = fill(), height = flex(), left = 4, right = 4, top = 2, bottom = 2
    ):
      with newRect(width = fill(), height = flex(2), bgColor = bgYellow)
      with newRect(width = fill(), height = flex(1), bgColor = bgBlue)
      with newRect(width = fill(), height = flex(1), bgColor = bgRed)

    with newLabel("Flex ratio 2:1:1 (Yellow:Blue:Red) - Press ESC or Q to exit")

  var key = getKey()
  while key != Key.Escape and key != Key.Q:
    sleep(20)
    key = getKey()

  exitProc()

when isMainModule:
  main()
