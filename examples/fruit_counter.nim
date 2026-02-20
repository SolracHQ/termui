import termui
import sugar

# State management - use ref object so it can be captured
type AppState = ref object
  apples: int
  oranges: int
  selectedButton: int
  hoveredButton: int

# Button component
proc button(text: string, id: int, state: AppState, onClick: proc()) {.widget.} =
  let isSelected = state.selectedButton == id
  let isHovered = state.hoveredButton == id
  let bg =
    if isSelected:
      bgYellow
    elif isHovered:
      bgBlue
    else:
      bgNone
  let fg = if isSelected or isHovered: fgBlack else: fgYellow

  self.modifier = newModifier(hasBorder = true, padding = padding(horizontal = 1))

  with newLabel(text, fgColor = fg, bgColor = bg, style = {styleBright})

  onEvent e:
    case e.kind
    of ekMouseMove:
      state.hoveredButton = id
      return true
    of ekMouseButton:
      if e.mouseButton.action == mbaPressed:
        state.selectedButton = id
        onClick()
        return true
    of ekKey:
      if e.key.name == "Enter" and isSelected:
        onClick()
        return true
    else:
      discard

# Counter display - single container with modifiers
proc counter(label: string, value: int, color: ForegroundColor) {.widget.} =
  with newContainer(
    modifier = newModifier(
      hasBorder = true, padding = padding(1), spacing = 1, alignment = alCenter
    ),
    direction = drVertical,
  ):
    with newLabel(label, fgColor = color, style = {styleBright})
    with newLabel($value, fgColor = fgWhite, style = {styleBright})

# Control buttons for a counter
proc counterControls(id1, id2: int, state: AppState, onDec, onInc: proc()) {.widget.} =
  with newContainer(modifier = newModifier(spacing = 1), direction = drHorizontal):
    with button("[-]", id1, state, onDec)
    with button("[+]", id2, state, onInc)

# Full counter section with display and controls
proc counterSection(
    label: string,
    value: int,
    color: ForegroundColor,
    decId, incId: int,
    state: AppState,
    onDec, onInc: proc(),
) {.widget.} =
  with newContainer(
    modifier = newModifier(spacing = 0, alignment = alCenter), direction = drVertical
  ):
    with counter(label, value, color)
    with counterControls(decId, incId, state, onDec, onInc)

proc main() {.tui.} =
  onInit:
    let state = AppState(apples: 5, oranges: 3, selectedButton: 0, hoveredButton: -1)

  self.modifier.spacing = 0

  # Title
  with newContainer(
    modifier = newModifier(
      hasBorder = true,
      padding = padding(vertical = 1),
      width = fill(),
      alignment = alCenter,
    )
  ):
    with newLabel(
      "🍎 Fruit Counter App 🍊", fgColor = fgYellow, style = {styleBright}
    )

  # Main content
  with newContainer(
    modifier = newModifier(
      padding = padding(horizontal = 4), width = fill(), alignment = alCenter
    ),
    direction = drVertical,
  ):
    # Counters row
    with newContainer(
      modifier = newModifier(spacing = 0, alignment = alCenter),
      direction = drHorizontal,
    ):
      with counterSection(
        "Apples",
        state.apples,
        fgRed,
        0,
        1,
        state,
        () => state.apples.dec(),
        () => state.apples.inc(),
      )
      with counterSection(
        "Oranges",
        state.oranges,
        fgYellow,
        2,
        3,
        state,
        () => state.oranges.dec(),
        () => state.oranges.inc(),
      )

    # Total
    with newContainer(modifier = newModifier(padding = padding(top = 1))):
      with newLabel(
        "Total: " & $(state.apples + state.oranges),
        fgColor = fgGreen,
        style = {styleBright},
      )

    # Action buttons
    with newContainer(modifier = newModifier(spacing = 1), direction = drHorizontal):
      with button(
        "Reset All",
        4,
        state,
        proc() =
          state.apples = 0
          state.oranges = 0,
      )
      with button("Quit", 5, state, quit)

  # Status bar
  with newContainer(
    modifier = newModifier(
      hasBorder = true,
      padding = padding(horizontal = 1),
      width = fill(),
      alignment = alCenter,
    )
  ):
    with newLabel(
      "TAB/Arrows: navigate • ENTER: activate • Mouse: click • ESC: quit",
      fgColor = fgCyan,
    )

  onEvent e:
    if e.kind == ekKey:
      case e.key.name
      of "Tab", "Right":
        state.selectedButton = (state.selectedButton + 1) mod 6
      of "Down":
        state.selectedButton = (state.selectedButton + 2) mod 6
      of "Left":
        state.selectedButton = (state.selectedButton - 1 + 6) mod 6
      of "Up":
        state.selectedButton = (state.selectedButton - 2 + 6) mod 6
      of "Escape", "Q":
        quit()
      else:
        discard

when isMainModule:
  main()
