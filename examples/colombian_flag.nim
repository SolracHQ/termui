import termui
import widgets
import layout

proc main() {.tui.} =
  self.alignment = alCenter

  onInit:
    var invert = false

  with newLabel("Colombian Flag", style = {styleBright}):
    self.text = $self.type & ": " & self.text

  with newPadding(
    width = fill(), height = flex(), left = 4, right = 4, top = 2, bottom = 2
  ):
    with newRect(
      width = fill(), height = flex(2), bgColor = if not invert: bgYellow else: bgRed
    )
    with newRect(width = fill(), height = flex(1), bgColor = bgBlue)
    with newRect(
      width = fill(), height = flex(1), bgColor = if not invert: bgRed else: bgYellow
    )
    onEvent e:
      if e.kind == evKey and (e.key == Key.I):
        invert = not invert

  with newLabel("Flex ratio 2:1:1 (Yellow:Blue:Red) - Press ESC or Q to exit")

  onEvent e:
    if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
      quit()

when isMainModule:
  main()
