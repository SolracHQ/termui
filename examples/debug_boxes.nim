import termui

proc main() {.tui.} =
  self.modifier.alignment = alCenter

  with newLabel(
    "Debug Box Rendering - Press D to toggle debug mode, ESC or Q to exit",
    style = {styleBright},
  )

  with newContainer(
    modifier = newModifier(
      width = fill(), height = flex(), padding = padding(horizontal = 4, vertical = 2)
    )
  ):
    with newContainer(
      modifier = newModifier(spacing = 1, alignment = alCenter),
      direction = drHorizontal,
    ):
      with newLabel("Box 1", width = fixed(20))
      with newLabel("Box 2", width = fixed(30))
      with newLabel("Box 3", width = fixed(15))

    with newContainer(
      modifier = newModifier(alignment = alCenter, width = fill(), height = flex())
    ):
      with newRect(width = fill(), height = flex(2), bgColor = bgYellow)
      with newRect(width = fill(), height = flex(1), bgColor = bgBlue)
      with newRect(width = fill(), height = flex(1), bgColor = bgRed)

  with newLabel("Colored boxes show widget boundaries and sizes")

  onEvent e:
    if e.kind == ekKey and (e.key.name == "Escape" or e.key.name == "Q"):
      quit()
    if e.kind == ekKey and e.key.name == "D":
      debugMode = not debugMode

when isMainModule:
  main()
