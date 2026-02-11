# mouse events are not working on windows I will test in linux later
import termui
import widgets
import layout
import os

proc main() =
  var counter = 0
  var file = open("counter.txt", fmReadWrite)
  tui:
    self.alignment = alCenter
    self.spacing = 2

    with newLabel("Counter Example", style = {styleBright})

    with newLabel($counter, fgColor = fgCyan, style = {styleBright})

    with newLabel("Increment", width = fixed(20)):
      onEvent e:
        if e.kind == evMouse and e.mouse.action == mbaPressed:
          counter.inc()
          return true

    with newLabel("Press ESC or Q to exit", fgColor = fgYellow)

    onEvent e:
      if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
        quit()
      if e.kind == evMouse:
        file.write($counter & "\n")

when isMainModule:
  main()
