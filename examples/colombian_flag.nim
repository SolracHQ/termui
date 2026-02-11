import termui
import widgets
import layout

proc main() =
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

    onEvent e:
      if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
        quit()

when isMainModule:
  main()
