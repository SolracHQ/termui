import termui
import widgets

proc main() {.tui.} =
  self.modifier.alignment = alCenter

  with newLabel("Colombian Flag", style = {styleBright})

  with newContainer(
    modifier = newModifier(
      width = fill(), height = flex(), padding(horizontal = 4, vertical = 1)
    )
  ):
    with newRect(width = fill(), height = flex(2), bgColor = bgYellow)
    with newRect(width = fill(), height = flex(1), bgColor = bgBlue)
    with newRect(width = fill(), height = flex(1), bgColor = bgRed)

  with newLabel("Flex ratio 2:1:1 (Yellow:Blue:Red) - Press ESC or Q to exit")

  onEvent e:
    if e.kind == ekKey and (e.key.name == "Escape" or e.key.name == "Q"):
      quit()

when isMainModule:
  main()
