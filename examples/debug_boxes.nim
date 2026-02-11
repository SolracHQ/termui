import termui
import widgets
import layout

proc main() =
  tuiDebug:
    self.alignment = alCenter

    with newLabel("Debug Box Rendering - Press ESC or Q to exit", style = {styleBright})

    with newPadding(
      width = fill(), height = flex(), left = 4, right = 4, top = 2, bottom = 2
    ):
      with newHBox(width = fill(), height = content(), spacing = 2):
        with newLabel("Box 1", width = fixed(20))
        with newLabel("Box 2", width = fixed(30))
        with newLabel("Box 3", width = fixed(15))

      with newVBox(width = fill(), height = flex(), alignment = alCenter):
        with newRect(width = fill(), height = flex(2), bgColor = bgYellow)
        with newRect(width = fill(), height = flex(1), bgColor = bgBlue)
        with newRect(width = fill(), height = flex(1), bgColor = bgRed)

    with newLabel("Colored boxes show widget boundaries and sizes")

    onEvent e:
      if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
        quit()

when isMainModule:
  main()
