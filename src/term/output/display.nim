## Display and rendering logic
## Handles outputting terminal buffers to actual terminal with double buffering support

import types
import buffer
import ../ctx
import ../platform

import std/[terminal, unicode]

export buffer

var
  gPrevTerminalBuffer {.threadvar.}: TerminalBuffer
  gCurrBg {.threadvar.}: types.BackgroundColor
  gCurrFg {.threadvar.}: types.ForegroundColor
  gCurrStyle {.threadvar.}: set[Style]

proc setAttribs(c: TerminalChar) =
  if c.bg == bgNone or c.fg == fgNone or c.style == {}:
    resetAttributes()
    gCurrBg = c.bg
    gCurrFg = c.fg
    gCurrStyle = c.style
    if gCurrBg != bgNone:
      setBackgroundColor(cast[terminal.BackgroundColor](gCurrBg))
    if gCurrFg != fgNone:
      setForegroundColor(cast[terminal.ForegroundColor](gCurrFg))
    if gCurrStyle != {}:
      setStyle(gCurrStyle)
  else:
    if c.bg != gCurrBg:
      gCurrBg = c.bg
      setBackgroundColor(cast[terminal.BackgroundColor](gCurrBg))
    if c.fg != gCurrFg:
      gCurrFg = c.fg
      setForegroundColor(cast[terminal.ForegroundColor](gCurrFg))
    if c.style != gCurrStyle:
      gCurrStyle = c.style
      setStyle(gCurrStyle)

proc setPos(x, y: Natural) =
  terminal.setCursorPos(x, y)

proc setXPos(x: Natural) =
  terminal.setCursorXPos(x)

proc displayFull(tb: TerminalBuffer) =
  var buf = ""

  proc flushBuf() =
    if buf.len > 0:
      put buf
      buf = ""

  for y in 0 ..< tb.height:
    setPos(0, y)
    for x in 0 ..< tb.width:
      let c = tb[x, y]
      if c.bg != gCurrBg or c.fg != gCurrFg or c.style != gCurrStyle:
        flushBuf()
        setAttribs(c)
      buf &= $c.ch
    flushBuf()

proc displayDiff(tb: TerminalBuffer) =
  var
    buf = ""
    bufXPos, bufYPos: Natural
    currXPos = -1
    currYPos = -1

  proc flushBuf() =
    if buf.len > 0:
      if currYPos != bufYPos:
        currXPos = bufXPos
        currYPos = bufYPos
        setPos(currXPos, currYPos)
      elif currXPos != bufXPos:
        currXPos = bufXPos
        setXPos(currXPos)
      put buf
      inc(currXPos, buf.runeLen)
      buf = ""

  for y in 0 ..< tb.height:
    bufXPos = 0
    bufYPos = y
    for x in 0 ..< tb.width:
      let c = tb[x, y]
      if c != gPrevTerminalBuffer[x, y] or c.forceWrite:
        if c.bg != gCurrBg or c.fg != gCurrFg or c.style != gCurrStyle:
          flushBuf()
          bufXPos = x
          setAttribs(c)
        buf &= $c.ch
      else:
        flushBuf()
        bufXPos = x + 1
    flushBuf()

var gDoubleBufferingEnabled = true

proc setDoubleBuffering*(enabled: bool) =
  ## Enables or disables double buffering (enabled by default).
  gDoubleBufferingEnabled = enabled
  gPrevTerminalBuffer = nil

proc hasDoubleBuffering*(): bool =
  ## Returns `true` if double buffering is enabled.
  ##
  ## If the module is not intialised, `TermError` is raised.
  checkInit()
  result = gDoubleBufferingEnabled

proc display*(tb: TerminalBuffer) =
  ## Outputs the contents of the terminal buffer to the actual terminal.
  ##
  ## If the module is not intialised, `TermError` is raised.
  checkInit()
  if not gTermCtx.fullRedrawNextFrame and gDoubleBufferingEnabled:
    if gPrevTerminalBuffer == nil:
      displayFull(tb)
      gPrevTerminalBuffer = newTerminalBufferFrom(tb)
    else:
      if tb.width == gPrevTerminalBuffer.width and
          tb.height == gPrevTerminalBuffer.height:
        displayDiff(tb)
        gPrevTerminalBuffer.copyFrom(tb)
      else:
        displayFull(tb)
        gPrevTerminalBuffer = newTerminalBufferFrom(tb)
    flushFile(stdout)
  else:
    displayFull(tb)
    flushFile(stdout)
    gTermCtx.fullRedrawNextFrame = false
