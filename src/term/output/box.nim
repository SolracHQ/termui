## Box drawing functionality
## Provides utilities for drawing boxes, lines and rectangles with UTF-8 characters

import types
import buffer
import slice
import std/unicode

import ../../core/primitives
import ../../core/error
import ../../core/context

const
  LEFT = 0x01
  RIGHT = 0x02
  UP = 0x04
  DOWN = 0x08
  H_DBL = 0x10
  V_DBL = 0x20

  HORIZ = LEFT or RIGHT
  VERT = UP or DOWN

const gBoxCharsUnicode: array[64, string] = block:
  var boxchars: array[64, string]

  boxchars[0] = " "

  boxchars[0 or 0 or 0 or 0] = " "
  boxchars[0 or 0 or 0 or LEFT] = "─"
  boxchars[0 or 0 or RIGHT or 0] = "─"
  boxchars[0 or 0 or RIGHT or LEFT] = "─"
  boxchars[0 or UP or 0 or 0] = "│"
  boxchars[0 or UP or 0 or LEFT] = "┘"
  boxchars[0 or UP or RIGHT or 0] = "└"
  boxchars[0 or UP or RIGHT or LEFT] = "┴"
  boxchars[DOWN or 0 or 0 or 0] = "│"
  boxchars[DOWN or 0 or 0 or LEFT] = "┐"
  boxchars[DOWN or 0 or RIGHT or 0] = "┌"
  boxchars[DOWN or 0 or RIGHT or LEFT] = "┬"
  boxchars[DOWN or UP or 0 or 0] = "│"
  boxchars[DOWN or UP or 0 or LEFT] = "┤"
  boxchars[DOWN or UP or RIGHT or 0] = "├"
  boxchars[DOWN or UP or RIGHT or LEFT] = "┼"

  boxchars[H_DBL or 0 or 0 or 0 or 0] = " "
  boxchars[H_DBL or 0 or 0 or 0 or LEFT] = "═"
  boxchars[H_DBL or 0 or 0 or RIGHT or 0] = "═"
  boxchars[H_DBL or 0 or 0 or RIGHT or LEFT] = "═"
  boxchars[H_DBL or 0 or UP or 0 or 0] = "│"
  boxchars[H_DBL or 0 or UP or 0 or LEFT] = "╛"
  boxchars[H_DBL or 0 or UP or RIGHT or 0] = "╘"
  boxchars[H_DBL or 0 or UP or RIGHT or LEFT] = "╧"
  boxchars[H_DBL or DOWN or 0 or 0 or 0] = "│"
  boxchars[H_DBL or DOWN or 0 or 0 or LEFT] = "╕"
  boxchars[H_DBL or DOWN or 0 or RIGHT or 0] = "╒"
  boxchars[H_DBL or DOWN or 0 or RIGHT or LEFT] = "╤"
  boxchars[H_DBL or DOWN or UP or 0 or 0] = "│"
  boxchars[H_DBL or DOWN or UP or 0 or LEFT] = "╡"
  boxchars[H_DBL or DOWN or UP or RIGHT or 0] = "╞"
  boxchars[H_DBL or DOWN or UP or RIGHT or LEFT] = "╪"

  boxchars[V_DBL or 0 or 0 or 0 or 0] = " "
  boxchars[V_DBL or 0 or 0 or 0 or LEFT] = "─"
  boxchars[V_DBL or 0 or 0 or RIGHT or 0] = "─"
  boxchars[V_DBL or 0 or 0 or RIGHT or LEFT] = "─"
  boxchars[V_DBL or 0 or UP or 0 or 0] = "║"
  boxchars[V_DBL or 0 or UP or 0 or LEFT] = "╜"
  boxchars[V_DBL or 0 or UP or RIGHT or 0] = "╙"
  boxchars[V_DBL or 0 or UP or RIGHT or LEFT] = "╨"
  boxchars[V_DBL or DOWN or 0 or 0 or 0] = "║"
  boxchars[V_DBL or DOWN or 0 or 0 or LEFT] = "╖"
  boxchars[V_DBL or DOWN or 0 or RIGHT or 0] = "╓"
  boxchars[V_DBL or DOWN or 0 or RIGHT or LEFT] = "╥"
  boxchars[V_DBL or DOWN or UP or 0 or 0] = "║"
  boxchars[V_DBL or DOWN or UP or 0 or LEFT] = "╢"
  boxchars[V_DBL or DOWN or UP or RIGHT or 0] = "╟"
  boxchars[V_DBL or DOWN or UP or RIGHT or LEFT] = "╫"

  boxchars[H_DBL or V_DBL or 0 or 0 or 0 or 0] = " "
  boxchars[H_DBL or V_DBL or 0 or 0 or 0 or LEFT] = "═"
  boxchars[H_DBL or V_DBL or 0 or 0 or RIGHT or 0] = "═"
  boxchars[H_DBL or V_DBL or 0 or 0 or RIGHT or LEFT] = "═"
  boxchars[H_DBL or V_DBL or 0 or UP or 0 or 0] = "║"
  boxchars[H_DBL or V_DBL or 0 or UP or 0 or LEFT] = "╝"
  boxchars[H_DBL or V_DBL or 0 or UP or RIGHT or 0] = "╚"
  boxchars[H_DBL or V_DBL or 0 or UP or RIGHT or LEFT] = "╩"
  boxchars[H_DBL or V_DBL or DOWN or 0 or 0 or 0] = "║"
  boxchars[H_DBL or V_DBL or DOWN or 0 or 0 or LEFT] = "╗"
  boxchars[H_DBL or V_DBL or DOWN or 0 or RIGHT or 0] = "╔"
  boxchars[H_DBL or V_DBL or DOWN or 0 or RIGHT or LEFT] = "╦"
  boxchars[H_DBL or V_DBL or DOWN or UP or 0 or 0] = "║"
  boxchars[H_DBL or V_DBL or DOWN or UP or 0 or LEFT] = "╣"
  boxchars[H_DBL or V_DBL or DOWN or UP or RIGHT or 0] = "╠"
  boxchars[H_DBL or V_DBL or DOWN or UP or RIGHT or LEFT] = "╬"

  boxchars

proc toUTF8String(c: BoxChar): string =
  gBoxCharsUnicode[c]

proc newBoxBuffer*(size: Size): BoxBuffer =
  ## Creates a new box buffer of the specified size.
  result = new BoxBuffer
  result.size = size
  newSeq(result.buf, size.width * size.height)

proc newBoxBuffer*(width, height: Natural): BoxBuffer =
  ## Creates a new box buffer of a fixed `width` and `height`.
  newBoxBuffer(size(width, height))

func width*(bb: BoxBuffer): Natural =
  ## Returns the width of the box buffer.
  result = bb.size.width

func height*(bb: BoxBuffer): Natural =
  ## Returns the height of the box buffer.
  result = bb.size.height

func size*(bb: BoxBuffer): Size =
  ## Returns the size of the box buffer.
  result = bb.size

proc `[]=`(bb: BoxBuffer, pos: Position, c: BoxChar) =
  if pos.x < bb.width and pos.y < bb.height:
    bb.buf[bb.width * pos.y + pos.x] = c

proc `[]=`(bb: BoxBuffer, x, y: Natural, c: BoxChar) =
  bb[position(x, y)] = c

func `[]`(bb: BoxBuffer, pos: Position): BoxChar =
  if pos.x < bb.width and pos.y < bb.height:
    result = bb.buf[bb.width * pos.y + pos.x]

func `[]`(bb: BoxBuffer, x, y: Natural): BoxChar =
  result = bb[position(x, y)]

proc copyFrom*(bb: BoxBuffer, src: BoxBuffer, srcRect: Rect, destPos: Position) =
  ## Copies the contents of the `src` box buffer into this one.
  ## A rectangular area defined by `srcRect` is copied from the source buffer
  ## to `destPos` in this buffer.
  ##
  ## If the extents of the area to be copied lie outside the extents of the
  ## buffers, the copied area will be clipped to the available area.
  let
    srcX = srcRect.pos.x
    srcY = srcRect.pos.y
    width = srcRect.size.width
    height = srcRect.size.height
    destX = destPos.x
    destY = destPos.y

    srcWidth = max(src.width - srcX, 0)
    srcHeight = max(src.height - srcY, 0)
    destWidth = max(bb.width - destX, 0)
    destHeight = max(bb.height - destY, 0)
    w = min(min(srcWidth, destWidth), width)
    h = min(min(srcHeight, destHeight), height)

  for yOffs in 0 ..< h:
    for xOffs in 0 ..< w:
      bb[xOffs + destX, yOffs + destY] = src[xOffs + srcX, yOffs + srcY]

proc copyFrom*(bb: BoxBuffer, src: BoxBuffer) =
  ## Copies the full contents of the `src` box buffer into this one.
  bb.copyFrom(src, rect(0, 0, src.width, src.height), position(0, 0))

proc newBoxBufferFrom*(src: BoxBuffer): BoxBuffer =
  ## Creates a new box buffer with the dimensions of the `src` buffer and
  ## copies its contents into the new buffer.
  var bb = newBoxBuffer(src.size)
  bb.copyFrom(src)
  result = bb

proc drawHorizLine*(
    bb: BoxBuffer, x1, x2, y: Natural, doubleStyle: bool = false, connect: bool = true
) =
  ## Draws a horizontal line into the box buffer. Set `doubleStyle` to `true`
  ## to draw double lines. Set `connect` to `true` to connect overlapping
  ## lines.
  if y >= bb.height:
    return
  var xStart = x1
  var xEnd = x2
  if xStart > xEnd:
    swap(xStart, xEnd)
  if xStart >= bb.width:
    return

  xEnd = min(xEnd, bb.width - 1)
  if connect:
    for x in xStart .. xEnd:
      var c = bb[x, y]
      var h: int
      if x == xStart:
        h = if (c and LEFT) > 0: HORIZ else: RIGHT
      elif x == xEnd:
        h = if (c and RIGHT) > 0: HORIZ else: LEFT
      else:
        h = HORIZ
      if doubleStyle:
        h = h or H_DBL
      bb[x, y] = c or h
  else:
    for x in xStart .. xEnd:
      var h = HORIZ
      if doubleStyle:
        h = h or H_DBL
      bb[x, y] = h

proc drawVertLine*(
    bb: BoxBuffer, x, y1, y2: Natural, doubleStyle: bool = false, connect: bool = true
) =
  ## Draws a vertical line into the box buffer. Set `doubleStyle` to `true` to
  ## draw double lines. Set `connect` to `true` to connect overlapping lines.
  if x >= bb.width:
    return
  var yStart = y1
  var yEnd = y2
  if yStart > yEnd:
    swap(yStart, yEnd)
  if yStart >= bb.height:
    return

  yEnd = min(yEnd, bb.height - 1)
  if connect:
    for y in yStart .. yEnd:
      var c = bb[x, y]
      var v: int
      if y == yStart:
        v = if (c and UP) > 0: VERT else: DOWN
      elif y == yEnd:
        v = if (c and DOWN) > 0: VERT else: UP
      else:
        v = VERT
      if doubleStyle:
        v = v or V_DBL
      bb[x, y] = c or v
  else:
    for y in yStart .. yEnd:
      var v = VERT
      if doubleStyle:
        v = v or V_DBL
      bb[x, y] = v

proc drawRect*(
    bb: BoxBuffer, rect: Rect, doubleStyle: bool = false, connect: bool = true
) =
  ## Draws a rectangle into the box buffer. Set `doubleStyle` to `true` to
  ## draw double lines. Set `connect` to `true` to connect overlapping lines.
  let x1 = rect.pos.x
  let y1 = rect.pos.y
  let x2 = rect.pos.x + rect.size.width - 1
  let y2 = rect.pos.y + rect.size.height - 1

  if abs(x1 - x2) < 1 or abs(y1 - y2) < 1:
    return

  if connect:
    bb.drawHorizLine(x1, x2, y1, doubleStyle)
    bb.drawHorizLine(x1, x2, y2, doubleStyle)
    bb.drawVertLine(x1, y1, y2, doubleStyle)
    bb.drawVertLine(x2, y1, y2, doubleStyle)
  else:
    bb.drawHorizLine(x1 + 1, x2 - 1, y1, doubleStyle, connect = false)
    bb.drawHorizLine(x1 + 1, x2 - 1, y2, doubleStyle, connect = false)
    bb.drawVertLine(x1, y1 + 1, y2 - 1, doubleStyle, connect = false)
    bb.drawVertLine(x2, y1 + 1, y2 - 1, doubleStyle, connect = false)

    var c = RIGHT or DOWN
    if doubleStyle:
      c = c or V_DBL or H_DBL
    bb[x1, y1] = c

    c = LEFT or DOWN
    if doubleStyle:
      c = c or V_DBL or H_DBL
    bb[x2, y1] = c

    c = RIGHT or UP
    if doubleStyle:
      c = c or V_DBL or H_DBL
    bb[x1, y2] = c

    c = LEFT or UP
    if doubleStyle:
      c = c or V_DBL or H_DBL
    bb[x2, y2] = c

proc drawRect*(
    bb: BoxBuffer,
    x1, y1, x2, y2: Natural,
    doubleStyle: bool = false,
    connect: bool = true,
) =
  ## Draws a rectangle into the box buffer. Set `doubleStyle` to `true` to
  ## draw double lines. Set `connect` to `true` to connect overlapping lines.
  let r = rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1)
  bb.drawRect(r, doubleStyle, connect)

proc write*(tb: TerminalBuffer, bb: BoxBuffer, pos: Position = position(0, 0)) =
  ## Writes the contents of the box buffer into this terminal buffer at the
  ## specified position with the current text attributes.
  let width = min(tb.width - pos.x, bb.width)
  let height = min(tb.height - pos.y, bb.height)
  var horizBoxCharCount: int
  var forceWrite: bool

  for y in 0 ..< height:
    horizBoxCharCount = 0
    forceWrite = false
    for x in 0 ..< width:
      let boxChar = bb[x, y]
      if boxChar > 0:
        if ((boxChar and LEFT) or (boxChar and RIGHT)) > 0:
          if horizBoxCharCount == 1:
            let prevPos = position(pos.x + x - 1, pos.y + y)
            var prev = tb[prevPos.x, prevPos.y]
            prev.forceWrite = true
            tb[prevPos.x, prevPos.y] = prev
          if horizBoxCharCount >= 1:
            forceWrite = true
          inc(horizBoxCharCount)
        else:
          horizBoxCharCount = 0
          forceWrite = false

        var c = TerminalChar(
          ch: toUTF8String(boxChar).runeAt(0),
          fg: tb.currFg,
          bg: tb.currBg,
          style: tb.currStyle,
          forceWrite: forceWrite,
        )
        tb[pos.x + x, pos.y + y] = c

proc write*(slice: TerminalSlice, bb: BoxBuffer, pos: Position = position(0, 0)) =
  ## Writes the contents of the box buffer into this terminal slice at the
  ## specified position (relative to slice) with the current text attributes.
  ## Raises an error if the box buffer would extend outside the slice bounds.
  if pos.x + bb.width > slice.width() or pos.y + bb.height > slice.height():
    raise newException(
      OutOfBoundsError,
      "Box buffer write would exceed slice bounds: " & "buffer size (" & $bb.width & ", " &
        $bb.height & ") " & "at position (" & $pos.x & ", " & $pos.y & ") " &
        "exceeds slice size (" & $slice.width() & ", " & $slice.height() & ")",
    )

  var horizBoxCharCount: int
  var forceWrite: bool

  for y in 0 ..< bb.height:
    horizBoxCharCount = 0
    forceWrite = false
    for x in 0 ..< bb.width:
      let boxChar = bb[x, y]
      if boxChar > 0:
        if ((boxChar and LEFT) or (boxChar and RIGHT)) > 0:
          if horizBoxCharCount == 1:
            let prevPos = position(pos.x + x - 1, pos.y + y)
            var prev = slice[prevPos]
            prev.forceWrite = true
            slice[prevPos] = prev
          if horizBoxCharCount >= 1:
            forceWrite = true
          inc(horizBoxCharCount)
        else:
          horizBoxCharCount = 0
          forceWrite = false

        var c = TerminalChar(
          ch: toUTF8String(boxChar).runeAt(0),
          fg: slice.getForegroundColor(),
          bg: slice.getBackgroundColor(),
          style: slice.getStyle(),
          forceWrite: forceWrite,
        )
        slice[pos.x + x, pos.y + y] = c

proc drawHorizLine*(tb: TerminalBuffer, x1, x2, y: Natural, doubleStyle: bool = false) =
  ## Convenience method to draw a single horizontal line into a terminal
  ## buffer directly.
  var bb = newBoxBuffer(tb.size)
  bb.drawHorizLine(x1, x2, y, doubleStyle)
  tb.write(bb)

proc drawVertLine*(tb: TerminalBuffer, x, y1, y2: Natural, doubleStyle: bool = false) =
  ## Convenience method to draw a single vertical line into a terminal buffer
  ## directly.
  var bb = newBoxBuffer(tb.size)
  bb.drawVertLine(x, y1, y2, doubleStyle)
  tb.write(bb)

proc drawRect*(tb: TerminalBuffer, rect: Rect, doubleStyle: bool = false) =
  ## Convenience method to draw a rectangle into a terminal buffer directly.
  var bb = newBoxBuffer(tb.size)
  bb.drawRect(rect, doubleStyle)
  tb.write(bb)

proc drawRect*(tb: TerminalBuffer, x1, y1, x2, y2: Natural, doubleStyle: bool = false) =
  ## Convenience method to draw a rectangle into a terminal buffer directly.
  tb.drawRect(rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1), doubleStyle)

proc drawHorizLine*(
    slice: TerminalSlice, x1, x2, y: Natural, doubleStyle: bool = false
) =
  ## Convenience method to draw a single horizontal line into a terminal
  ## slice directly.
  var bb = newBoxBuffer(slice.size)
  bb.drawHorizLine(x1, x2, y, doubleStyle)
  slice.write(bb)

proc drawVertLine*(
    slice: TerminalSlice, x, y1, y2: Natural, doubleStyle: bool = false
) =
  ## Convenience method to draw a single vertical line into a terminal slice
  ## directly.
  var bb = newBoxBuffer(slice.size)
  bb.drawVertLine(x, y1, y2, doubleStyle)
  slice.write(bb)

proc drawRect*(slice: TerminalSlice, rect: Rect, doubleStyle: bool = false) =
  ## Convenience method to draw a rectangle into a terminal slice directly.
  var bb = newBoxBuffer(slice.size)
  bb.drawRect(rect, doubleStyle)
  slice.write(bb)

proc drawRect*(
    slice: TerminalSlice, x1, y1, x2, y2: Natural, doubleStyle: bool = false
) =
  ## Convenience method to draw a rectangle into a terminal slice directly.
  slice.drawRect(rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1), doubleStyle)
