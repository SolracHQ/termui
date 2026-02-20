## High-level terminal application API
## Provides a game-loop style interface for terminal applications

import term/lifecycle
import term/input
import term/ctx
import term/output
import std/times

from std/terminal import showCursor, hideCursor, terminalWidth, terminalHeight

export input, ctx, output

type FrameResult* {.pure.} = enum
  frDisplay ## Redraw the terminal buffer
  frPreserve ## Keep current display, don't redraw
  frExit ## Exit the application loop

template onTerm*(
    fullscreen: bool = true, mouse: bool = false, targetFps: int = 60, body: untyped
) =
  ## High-level terminal application entry point.
  ##
  ## Sets up the terminal, runs the main loop, and cleans up on exit.
  ##
  ## The body has access to injected variables:
  ## - `delta`: float - Time since last frame in seconds
  ## - `tb`: var TerminalBuffer - Terminal buffer to draw to
  ## - `events`: seq[Event] - All events since last frame (includes ekUpdate and ekResize)
  ##
  ## Events injected automatically:
  ## - `ekUpdate`: Sent every frame with delta time
  ## - `ekResize`: Sent when terminal size changes
  ## - `ekFrameLag`: Sent when frame takes longer than target
  ##
  ## The body should evaluate to FrameResult:
  ## - `frDisplay`: Redraw the terminal
  ## - `frPreserve`: Don't redraw
  ## - `frExit`: Exit the loop
  ##
  ## Example:
  ## ```nim
  ## var counter = 0
  ## onTerm(fullscreen = true, mouse = true, targetFps = 60):
  ##   for event in events:
  ##     case event.kind
  ##     of ekKey:
  ##       if event.key.code == ord('q'):
  ##         frExit
  ##     of ekUpdate:
  ##       counter += 1  # Runs every frame
  ##     of ekResize:
  ##       echo "Terminal resized to: ", event.size
  ##     else:
  ##       discard
  ##
  ##   tb.clear()
  ##   tb.write(0, 0, "Counter: " & $counter)
  ##   frDisplay
  ## ```

  let frameDurationMs =
    if targetFps > 0:
      1000 div targetFps
    else:
      0

  # Setup Ctrl+C handler to ensure proper cleanup
  proc ctrlCHook() {.noconv.} =
    termDeinit()
    showCursor()
    quit(0)

  setControlCHook(ctrlCHook)

  # Initialize terminal
  termInit(fullscreen, mouse)
  hideCursor()

  # Track terminal size for resize detection
  var lastWidth = terminalWidth()
  var lastHeight = terminalHeight()

  # Create terminal buffer - injected into body scope
  var tb {.inject.} = newTerminalBuffer(lastWidth, lastHeight)

  var lastFrameTime = cpuTime()
  var running = true
  # Events list - injected into body scope
  var events {.inject.}: seq[Event] = @[]

  try:
    while running:
      let frameStartTime = cpuTime()

      # Calculate delta time - injected into body scope
      let delta {.inject.} = frameStartTime - lastFrameTime
      lastFrameTime = frameStartTime

      # Check for terminal resize
      let currentWidth = terminalWidth()
      let currentHeight = terminalHeight()

      tb = newTerminalBuffer(currentWidth, currentHeight)

      # Collect events for next frame (start fresh)
      events = @[]

      # Always inject ekUpdate event with delta time
      events.add(Event(kind: ekUpdate, delta: delta))

      # Inject ekResize event if terminal size changed
      if currentWidth != lastWidth or currentHeight != lastHeight:
        events.add(
          Event(kind: ekResize, size: Size(width: currentWidth, height: currentHeight))
        )
        lastWidth = currentWidth
        lastHeight = currentHeight

      # Calculate remaining time in frame for event collection
      let frameEndTime = cpuTime()
      let frameElapsedMs = ((frameEndTime - frameStartTime) * 1000.0).int

      if frameDurationMs > 0:
        let remainingMs = frameDurationMs - frameElapsedMs

        if remainingMs < 0:
          # Frame overrun - add lag event
          events.add(Event(kind: ekFrameLag, lagMs: -remainingMs))
        else:
          # Collect input events for remaining time
          let deadline = cpuTime() + (remainingMs.float / 1000.0)
          while cpuTime() < deadline:
            let timeLeft = ((deadline - cpuTime()) * 1000.0).int
            if timeLeft <= 0:
              break
            let event = getEventWithTimeout(timeLeft)
            if event.kind == ekNone:
              break
            events.add(event)
      else:
        # No frame limit - just collect available events
        var event = getEvent()
        while event.kind != ekNone:
          events.add(event)
          event = getEvent()

      # Execute user's body (with delta, tb, events available)
      let result = body

      # Handle result
      case result
      of frExit:
        running = false
        continue
      of frDisplay:
        tb.display()
      of frPreserve:
        discard
  finally:
    # Cleanup
    termDeinit()
    showCursor()
