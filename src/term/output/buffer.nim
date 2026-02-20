## Terminal buffer operations
## Provides virtual terminal buffer with cursor positioning and text attributes

import types
import std/[unicode, terminal]
import ../../core/primitives

export types

# Original index operators remain for internal use
proc `[]=`*(tb: TerminalBuffer, x, y: Natural, ch: TerminalChar) =
  ## Index operator to write a character into the terminal buffer at the
  ## specified location. Does nothing if the location is outside of the
  ## extents of the terminal buffer.
  if x < tb.width and y < tb.height:
    tb.buf[tb.width * y + x] = ch

proc `[]`*(tb: TerminalBuffer, x, y: Natural): TerminalChar =
  ## Index operator to read a character from the terminal buffer at the
  ## specified location. Returns nil if the location is outside of the extents
  ## of the terminal buffer.
  if x < tb.width and y < tb.height:
    result = tb.buf[tb.width * y + x]

# New primitive-based operations

proc fill*(tb: TerminalBuffer, rect: Rect, ch: string = " ") =
  ## Fills a rectangular area with the `ch` character using the current text
  ## attributes. The rectangle is clipped to the extends of the terminal
  ## buffer and the call can never fail.
  let x1 = rect.pos.x
  let y1 = rect.pos.y
  let x2 = rect.pos.x + rect.size.width - 1
  let y2 = rect.pos.y + rect.size.height - 1

  if x1 < tb.width and y1 < tb.height:
    let
      c = TerminalChar(
        ch: ch.runeAt(0), fg: tb.currFg, bg: tb.currBg, style: tb.currStyle
      )
      xe = min(x2, tb.width - 1)
      ye = min(y2, tb.height - 1)

    for y in y1 .. ye:
      for x in x1 .. xe:
        tb[x, y] = c

proc clear*(tb: TerminalBuffer, ch: string = " ") =
  ## Clears the contents of the terminal buffer with the `ch` character using
  ## the `fgNone` and `bgNone` attributes.
  let fullRect = rect(0, 0, tb.width, tb.height)
  tb.fill(fullRect, ch)

proc initTerminalBuffer(tb: TerminalBuffer, width, height: Natural) =
  ## Initializes a new terminal buffer object of a fixed `width` and `height`.
  tb.width = width
  tb.height = height
  newSeq(tb.buf, width * height)
  tb.currBg = bgNone
  tb.currFg = fgNone
  tb.currStyle = {}

proc newTerminalBuffer*(width, height: Natural): TerminalBuffer =
  ## Creates a new terminal buffer of a fixed `width` and `height`.
  var tb = new TerminalBuffer
  tb.initTerminalBuffer(width, height)
  tb.clear()
  result = tb

proc newTerminalBuffer*(size: Size): TerminalBuffer =
  ## Creates a new terminal buffer with the specified size.
  newTerminalBuffer(size.width, size.height)

func width*(tb: TerminalBuffer): Natural =
  ## Returns the width of the terminal buffer.
  result = tb.width

func height*(tb: TerminalBuffer): Natural =
  ## Returns the height of the terminal buffer.
  result = tb.height

func size*(tb: TerminalBuffer): Size =
  ## Returns the size of the terminal buffer.
  result = size(tb.width, tb.height)

proc copyFrom*(
    tb: TerminalBuffer,
    src: TerminalBuffer,
    srcRect: Rect,
    destPos: Position,
    transparency = false,
) =
  ## Copies the contents of the `src` terminal buffer into this one.
  ## A rectangular area defined by `srcRect` is copied from the source buffer
  ## to the position `destPos` in this buffer.
  ##
  ## If the extents of the area to be copied lie outside the extents of the
  ## buffers, the copied area will be clipped to the available area (in other
  ## words, the call can never fail; in the worst case it just copies
  ## nothing).
  ##
  ## If `transparency` is `true`, white-space characters in the source buffer
  ## will not overwrite the contents of the target buffer (they're treated as
  ## transparent).
  let
    srcX = srcRect.pos.x
    srcY = srcRect.pos.y
    width = srcRect.size.width
    height = srcRect.size.height
    destX = destPos.x
    destY = destPos.y

    srcWidth = max(src.width - srcX, 0)
    srcHeight = max(src.height - srcY, 0)
    destWidth = max(tb.width - destX, 0)
    destHeight = max(tb.height - destY, 0)
    w = min(min(srcWidth, destWidth), width)
    h = min(min(srcHeight, destHeight), height)

  for yOffs in 0 ..< h:
    for xOffs in 0 ..< w:
      let tc = src[xOffs + srcX, yOffs + srcY]
      if (not transparency) or (not tc.ch.isWhiteSpace):
        tb[xOffs + destX, yOffs + destY] = tc

proc copyFrom*(tb: TerminalBuffer, src: TerminalBuffer, transparency = false) =
  ## Copies the full contents of the `src` terminal buffer into this one.
  ##
  ## If the extents of the source buffer is greater than the extents of the
  ## destination buffer, the copied area is clipped to the destination area.
  ##
  ## If `transparency` is `true`, white-space characters in the source buffer
  ## will not overwrite the contents of the target buffer (they're treated as
  ## transparent).
  let srcRect = rect(0, 0, src.width, src.height)
  let destPos = position(0, 0)
  tb.copyFrom(src, srcRect, destPos, transparency)

proc newTerminalBufferFrom*(src: TerminalBuffer): TerminalBuffer =
  ## Creates a new terminal buffer with the dimensions of the `src` buffer and
  ## copies its contents into the new buffer.
  var tb = new TerminalBuffer
  tb.initTerminalBuffer(src.width, src.height)
  tb.copyFrom(src)
  result = tb

proc setCursorPos*(tb: TerminalBuffer, pos: Position) =
  ## Sets the current cursor position.
  tb.currX = pos.x
  tb.currY = pos.y

proc setCursorPos*(tb: TerminalBuffer, x, y: Natural) =
  ## Sets the current cursor position.
  tb.setCursorPos(position(x, y))

proc setCursorXPos*(tb: TerminalBuffer, x: Natural) =
  ## Sets the current X cursor position.
  tb.currX = x

proc setCursorYPos*(tb: TerminalBuffer, y: Natural) =
  ## Sets the current Y cursor position.
  tb.currY = y

proc setBackgroundColor*(tb: TerminalBuffer, bg: types.BackgroundColor) =
  ## Sets the current background color.
  tb.currBg = bg

proc setForegroundColor*(
    tb: TerminalBuffer, fg: types.ForegroundColor, bright: bool = false
) =
  ## Sets the current foreground color and the bright style flag.
  if bright:
    incl(tb.currStyle, styleBright)
  else:
    excl(tb.currStyle, styleBright)
  tb.currFg = fg

proc setStyle*(tb: TerminalBuffer, style: set[Style]) =
  ## Sets the current style flags.
  tb.currStyle = style

func getCursorPos*(tb: TerminalBuffer): Position =
  ## Returns the current cursor position.
  result = position(tb.currX, tb.currY)

func getCursorXPos*(tb: TerminalBuffer): Natural =
  ## Returns the current X cursor position.
  result = tb.currX

func getCursorYPos*(tb: TerminalBuffer): Natural =
  ## Returns the current Y cursor position.
  result = tb.currY

func getBackgroundColor*(tb: TerminalBuffer): types.BackgroundColor =
  ## Returns the current background color.
  result = tb.currBg

func getForegroundColor*(tb: TerminalBuffer): types.ForegroundColor =
  ## Returns the current foreground color.
  result = tb.currFg

func getStyle*(tb: TerminalBuffer): set[Style] =
  ## Returns the current style flags.
  result = tb.currStyle

proc resetAttributes*(tb: TerminalBuffer) =
  ## Resets the current text attributes to `bgNone`, `fgWhite` and clears
  ## all style flags.
  tb.setBackgroundColor(bgNone)
  tb.setForegroundColor(fgWhite)
  tb.setStyle({})

proc write*(tb: TerminalBuffer, pos: Position, s: string) =
  ## Writes `s` into the terminal buffer at the specified position using
  ## the current text attributes. Lines do not wrap and attempting to write
  ## outside the extents of the buffer will not raise an error; the output
  ## will be just cropped to the extents of the buffer.
  var currX = pos.x
  let y = pos.y
  for ch in runes(s):
    var c = TerminalChar(ch: ch, fg: tb.currFg, bg: tb.currBg, style: tb.currStyle)
    tb[currX, y] = c
    inc(currX)
  tb.currX = currX
  tb.currY = y

proc write*(tb: TerminalBuffer, x, y: Natural, s: string) =
  ## Writes `s` into the terminal buffer at the specified position using
  ## the current text attributes. Lines do not wrap and attempting to write
  ## outside the extents of the buffer will not raise an error; the output
  ## will be just cropped to the extents of the buffer.
  tb.write(position(x, y), s)

proc write*(tb: TerminalBuffer, s: string) =
  ## Writes `s` into the terminal buffer at the current cursor position using
  ## the current text attributes.
  write(tb, tb.getCursorPos(), s)
