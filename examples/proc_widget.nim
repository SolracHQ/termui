import termui
import widgets
import layout
import sugar

# Define reusable widget components using the {.widget.} pragma

proc button(text: string, isSelected: bool, onClick: proc()) {.widget.} =
  ## A simple button widget with border and click handling
  let bgColor = if isSelected: bgYellow else: bgNone
  let fgColor = if isSelected: fgBlack else: fgYellow

  with newPadding(width = content(), height = content(), left = 1, right = 1):
    with newLabel(text, fgColor = fgColor, bgColor = bgColor, style = {styleBright}):
      onEvent e:
        if e.kind == evKey and e.key == Key.Enter and isSelected:
          onClick()
          return true

proc statusBar(message: string) {.widget.} =
  ## A status bar at the bottom of the screen
  with newLabel(message, fgColor = fgCyan)

# Main application using the widget components

proc main() =
  tui:
    onInit:
      var apples = 5
      var oranges = 3
      var selectedButton = 0
        # 0: apples-, 1: apples+, 2: oranges-, 3: oranges+, 4: reset, 5: quit

    self.alignment = alCenter
    self.spacing = 2

    with newLabel("Fruit Counter App", style = {styleBright}, fgColor = fgWhite)

    with newVBox(width = content(), height = content(), spacing = 1):
      with newLabel("Apples: " & $apples, fgColor = fgCyan, style = {styleBright})

      with newHBox(width = content(), height = content(), spacing = 2):
        with button("[-]", selectedButton == 0, () => apples.dec())
        with button("[+]", selectedButton == 1, () => apples.inc())

    with newVBox(width = content(), height = content(), spacing = 1):
      with newLabel("Oranges: " & $oranges, fgColor = fgCyan, style = {styleBright})

      with newHBox(width = content(), height = content(), spacing = 1):
        with button("[-]", selectedButton == 2, () => oranges.dec())
        with button("[+]", selectedButton == 3, () => oranges.inc())

    with newHBox(width = content(), height = content(), spacing = 2):
      with button(
        "Reset All",
        selectedButton == 4,
        proc() =
          apples = 0
          oranges = 0,
      )

      with button("Quit", selectedButton == 5, () => quit())

    with statusBar("Use TAB/Arrow keys to navigate, ENTER to activate")

    onEvent e:
      if e.kind == evKey:
        case e.key
        of Key.Tab, Key.Right:
          selectedButton = (selectedButton + 1) mod 6
          return true
        of Key.Down:
          selectedButton = (selectedButton + 2) mod 6
          return true
        of Key.Left:
          selectedButton = (selectedButton - 1 + 6) mod 6
          return true
        of Key.Up:
          selectedButton = (selectedButton - 2 + 6) mod 6
        of Key.Escape:
          quit()
        else:
          discard

when isMainModule:
  main()
