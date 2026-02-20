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
  let frameDurationSec =
    if targetFps > 0:
      1.0 / targetFps.float
    else:
      0.0
  let frameDurationMs =
    if targetFps > 0:
      1000 div targetFps
    else:
      0

  proc ctrlCHook() {.noconv.} =
    termDeinit()
    showCursor()
    quit(0)

  setControlCHook(ctrlCHook)

  termInit(fullscreen, mouse)
  hideCursor()

  var lastWidth = terminalWidth()
  var lastHeight = terminalHeight()
  var tb {.inject.} = newTerminalBuffer(lastWidth, lastHeight)
  var events {.inject.}: seq[Event] = @[]

  var lastFrameStart = cpuTime()
  var running = true

  try:
    while running:
      let frameStart = cpuTime()
      let delta {.inject.} = frameStart - lastFrameStart
      lastFrameStart = frameStart

      events.setLen(0)
      events.add(Event(kind: ekUpdate, delta: delta))

      let w = terminalWidth()
      let h = terminalHeight()
      if w != lastWidth or h != lastHeight:
        lastWidth = w
        lastHeight = h
        tb = newTerminalBuffer(w, h)
        events.add(Event(kind: ekResize, size: Size(width: w, height: h)))
      else:
        tb = newTerminalBuffer(w, h)

      if frameDurationMs > 0:
        let deadline = cpuTime() + (frameDurationMs.float / 1000.0)
        while true:
          let remaining = ((deadline - cpuTime()) * 1000.0).int
          if remaining <= 0:
            break
          let ev = getEvent()
          if ev.kind == ekNone:
            continue
          events.add(ev)
      else:
        # Unlimited FPS: drain whatever is available right now, then yield
        var ev = getEvent()
        while ev.kind != ekNone:
          events.add(ev)
          ev = getEvent()

      # --- Run user body ---
      case (body)
      of frExit:
        running = false
      of frDisplay:
        tb.display()
      of frPreserve:
        discard
  finally:
    termDeinit()
    showCursor()
