import termui

type AppState = ref object
  elapsed: float
  running: bool
  showDialog: bool
  setInput: int
  frame: int
  fps: float

proc timerDisplay(state: AppState) {.widget.} =
  with newContainer(
    modifier =
      newModifier(hasBorder = true, padding = padding(horizontal = 4, vertical = 1))
  ):
    let secs = max(0, state.setInput - int(state.elapsed))
    let label =
      if state.running:
        "Time remaining: " & $secs & "s"
      else:
        "Time remaining: " & $secs & "s  (paused)"
    with newLabel(label, fgColor = fgCyan, style = {styleBright})

proc btn(text: string, onClick: proc()) {.widget.} =
  with newContainer(
    modifier = newModifier(hasBorder = true, padding = padding(horizontal = 1))
  ):
    with newLabel(text, fgColor = fgYellow, style = {styleBright}):
      onEvent e:
        if e.kind == ekMouseButton and e.mouseButton.action == mbaPressed:
          onClick()
          return true

proc dialog(state: AppState) {.widget.} =
  self.direction = drStack
  self.modifier = newModifier(
    hasBackground = true,
    bgColor = bgBlack,
    alignment = alCenter,
    width = fill(),
    height = fill(),
  )
  with newContainer(
    modifier = newModifier(width = fill(), height = fill(), alignment = alCenter)
  ):
    with newContainer(
      modifier = newModifier(
        hasBorder = true,
        doubleStyle = true,
        padding = padding(horizontal = 4, vertical = 1),
        spacing = 1,
        alignment = alCenter,
      ),
      direction = drVertical,
    ):
      with newLabel("Congratulations!", fgColor = fgYellow, style = {styleBright})
      with newLabel(
        "You waited " & $state.setInput & " whole seconds for this.", fgColor = fgWhite
      )
      with newLabel("Truly a person of infinite patience.", fgColor = fgGreen)
      with btn(
        "[ Close ]",
        proc() =
          state.showDialog = false
          state.elapsed = 0
          state.running = true,
      )

import macros
proc main() {.tui, expandMacros.} =
  onInit:
    let state = AppState(elapsed: 0, running: true, showDialog: false, setInput: 10)

  self.direction = drStack

  with newContainer(
    modifier = newModifier(width = fill(), height = fill(), alignment = alCenter),
    direction = drVertical,
  ):
    with newLabel("Timer Dialog Example", fgColor = fgYellow, style = {styleBright})
    with timerDisplay(state)

    with newContainer(
      modifier = newModifier(spacing = 1, alignment = alCenter),
      direction = drHorizontal,
    ):
      with btn(
        if state.running: "Pause" else: "Resume",
        proc() =
          state.running = not state.running,
      )
      with btn(
        "Restart",
        proc() =
          state.elapsed = 0
          state.running = true,
      )
      with btn(
        "Set 5s",
        proc() =
          state.setInput = 5
          state.elapsed = 0
          state.running = true,
      )
      with btn(
        "Set 30s",
        proc() =
          state.setInput = 30
          state.elapsed = 0
          state.running = true,
      )

    with newLabel("Click buttons with mouse  |  ESC to quit", fgColor = fgCyan)
    with newLabel(
      "Frame: " & $state.frame & "  |  FPS: " & $int(state.fps), fgColor = fgCyan
    )

  if state.showDialog:
    with dialog(state)

  onEvent e:
    case e.kind
    of ekUpdate:
      state.frame += 1
      state.fps = 1.0 / (e.delta)
      if state.running and not state.showDialog:
        state.elapsed += e.delta
        if state.elapsed >= float(state.setInput):
          state.elapsed = float(state.setInput)
          state.running = false
          state.showDialog = true
    of ekKey:
      if e.key.name == "Escape":
        quit()
    else:
      discard

when isMainModule:
  main()
