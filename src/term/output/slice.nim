## Terminal slice operations
## Provides a safe view into a TerminalBuffer with bounds checking and coordinate translation

import types
import buffer
import ../../core/primitives
import ../../core/error
import ../../core/context
import std/[unicode, terminal]

export types

proc newSlice*(tb: TerminalBuffer, rect: Rect): TerminalSlice =
  ## Creates a new TerminalSlice that represents a portion of the terminal buffer defined by rect.
  result = TerminalSlice(tb: tb, rect: rect)

proc width*(slice: TerminalSlice): Natural =
  ## Returns the width of the TerminalSlice.
  slice.rect.size.width

proc height*(slice: TerminalSlice): Natural =
  ## Returns the height of the TerminalSlice.
  slice.rect.size.height

proc size*(slice: TerminalSlice): Size =
  ## Returns the size of the TerminalSlice.
  slice.rect.size

proc absPos*(slice: TerminalSlice, pos: Position): Position =
  ## Converts a local position (relative to slice) to absolute buffer position.
  position(slice.rect.pos.x + pos.x, slice.rect.pos.y + pos.y)

proc absPos*(slice: TerminalSlice, x, y: Natural): Position =
  ## Converts local coordinates to absolute buffer position.
  slice.absPos(position(x, y))

proc checkBounds*(slice: TerminalSlice, x, y: Natural) =
  ## Checks if the given coordinates are within the slice bounds.
  ## Raises an error if out of bounds.
  if x >= slice.width() or y >= slice.height():
    raise newException(
      OutOfBoundsError,
      "Slice write out of bounds: (" & $x & ", " & $y & ") " & "not in (0, 0, " &
        $slice.width() & ", " & $slice.height() & ")",
    )

proc checkBounds*(slice: TerminalSlice, pos: Position) =
  ## Checks if the given position is within the slice bounds.
  slice.checkBounds(pos.x, pos.y)

# Index operators with bounds checking

proc `[]=`*(slice: TerminalSlice, x: Natural, y: Natural, ch: TerminalChar) =
  ## Writes a character to the TerminalSlice at the specified (x, y) coordinates.
  ## The (x, y) coordinates are relative to the top-left corner of the slice.
  ## Raises an error if the coordinates are out of bounds of the slice.
  slice.checkBounds(x, y)
  let abs = slice.absPos(x, y)
  slice.tb[abs.x, abs.y] = ch

proc `[]=`*(slice: TerminalSlice, pos: Position, ch: TerminalChar) =
  ## Writes a character to the TerminalSlice at the specified position.
  slice[pos.x, pos.y] = ch

proc `[]`*(slice: TerminalSlice, x: Natural, y: Natural): TerminalChar =
  ## Reads a character from the TerminalSlice at the specified (x, y) coordinates.
  ## The (x, y) coordinates are relative to the top-left corner of the slice.
  ## Raises an error if the coordinates are out of bounds of the slice.
  slice.checkBounds(x, y)
  let abs = slice.absPos(x, y)
  result = slice.tb[abs.x, abs.y]

proc `[]`*(slice: TerminalSlice, pos: Position): TerminalChar =
  ## Reads a character from the TerminalSlice at the specified position.
  result = slice[pos.x, pos.y]

# Fill operations

proc fill*(slice: TerminalSlice, rect: Rect, ch: string = " ") =
  ## Fills a rectangular area within the slice with the `ch` character.
  ## The rect coordinates are relative to the slice.
  ## Raises an error if any part of the rect is outside the slice bounds.

  # Check if rect is within slice bounds
  let x1 = rect.pos.x
  let y1 = rect.pos.y
  let x2 = rect.pos.x + rect.size.width - 1
  let y2 = rect.pos.y + rect.size.height - 1

  if x2 >= slice.width() or y2 >= slice.height():
    raise newException(
      OutOfBoundsError,
      "Fill rect out of bounds: rect(" & $x1 & ", " & $y1 & ", " & $(x2 - x1 + 1) & ", " &
        $(y2 - y1 + 1) & ") " & "not in (0, 0, " & $slice.width() & ", " &
        $slice.height() & ")",
    )

  # Convert to absolute coordinates and fill in underlying buffer
  let absRect = rect(
    slice.rect.pos.x + rect.pos.x,
    slice.rect.pos.y + rect.pos.y,
    rect.size.width,
    rect.size.height,
  )
  slice.tb.fill(absRect, ch)

proc fill*(slice: TerminalSlice, x1, y1, x2, y2: Natural, ch: string = " ") =
  ## Fills a rectangular area within the slice with the `ch` character.
  ## Coordinates are relative to the slice and specify inclusive bounds.
  let r = rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1)
  slice.fill(r, ch)

proc clear*(slice: TerminalSlice, ch: string = " ") =
  ## Clears the entire slice with the `ch` character using the current attributes.
  let fullRect = rect(0, 0, slice.width(), slice.height())
  slice.fill(fullRect, ch)

# Cursor operations

proc setCursorPos*(slice: TerminalSlice, pos: Position) =
  ## Sets the current cursor position (relative to slice).
  slice.checkBounds(pos)
  let abs = slice.absPos(pos)
  slice.tb.setCursorPos(abs)

proc setCursorPos*(slice: TerminalSlice, x, y: Natural) =
  ## Sets the current cursor position (relative to slice).
  slice.setCursorPos(position(x, y))

proc setCursorXPos*(slice: TerminalSlice, x: Natural) =
  ## Sets the current X cursor position (relative to slice).
  if x >= slice.width():
    raise newException(
      OutOfBoundsError, "Cursor X out of bounds: " & $x & " >= " & $slice.width()
    )
  slice.tb.setCursorXPos(slice.rect.pos.x + x)

proc setCursorYPos*(slice: TerminalSlice, y: Natural) =
  ## Sets the current Y cursor position (relative to slice).
  if y >= slice.height():
    raise newException(
      OutOfBoundsError, "Cursor Y out of bounds: " & $y & " >= " & $slice.height()
    )
  slice.tb.setCursorYPos(slice.rect.pos.y + y)

proc getCursorPos*(slice: TerminalSlice): Position =
  ## Returns the current cursor position (relative to slice).
  let abs = slice.tb.getCursorPos()
  result = position(abs.x - slice.rect.pos.x, abs.y - slice.rect.pos.y)

proc getCursorXPos*(slice: TerminalSlice): Natural =
  ## Returns the current X cursor position (relative to slice).
  result = slice.tb.getCursorXPos() - slice.rect.pos.x

proc getCursorYPos*(slice: TerminalSlice): Natural =
  ## Returns the current Y cursor position (relative to slice).
  result = slice.tb.getCursorYPos() - slice.rect.pos.y

# Style operations (these just delegate to underlying buffer)

proc setBackgroundColor*(slice: TerminalSlice, bg: types.BackgroundColor) =
  ## Sets the current background color.
  slice.tb.setBackgroundColor(bg)

proc setForegroundColor*(
    slice: TerminalSlice, fg: types.ForegroundColor, bright: bool = false
) =
  ## Sets the current foreground color and the bright style flag.
  slice.tb.setForegroundColor(fg, bright)

proc setStyle*(slice: TerminalSlice, style: set[Style]) =
  ## Sets the current style flags.
  slice.tb.setStyle(style)

proc getBackgroundColor*(slice: TerminalSlice): types.BackgroundColor =
  ## Returns the current background color.
  result = slice.tb.getBackgroundColor()

proc getForegroundColor*(slice: TerminalSlice): types.ForegroundColor =
  ## Returns the current foreground color.
  result = slice.tb.getForegroundColor()

proc getStyle*(slice: TerminalSlice): set[Style] =
  ## Returns the current style flags.
  result = slice.tb.getStyle()

proc resetAttributes*(slice: TerminalSlice) =
  ## Resets the current text attributes to `bgNone`, `fgWhite` and clears
  ## all style flags.
  slice.tb.resetAttributes()

# Write operations

proc write*(slice: TerminalSlice, pos: Position, s: string) =
  ## Writes `s` into the slice at the specified position using the current
  ## text attributes. The position is relative to the slice.
  ## Raises an error if the write would go outside the slice bounds.
  slice.checkBounds(pos)

  # Check if the entire string fits
  let endX = pos.x + s.runeLen() - 1
  if endX >= slice.width():
    raise newException(
      OutOfBoundsError,
      "Write would exceed slice bounds: text length " & $s.runeLen() & " at position (" &
        $pos.x & ", " & $pos.y & ") " & "exceeds width " & $slice.width(),
    )

  # Convert to absolute position and write
  let abs = slice.absPos(pos)
  slice.tb.write(abs, s)

proc write*(slice: TerminalSlice, x, y: Natural, s: string) =
  ## Writes `s` into the slice at the specified coordinates using the current
  ## text attributes. Coordinates are relative to the slice.
  slice.write(position(x, y), s)

proc write*(slice: TerminalSlice, s: string) =
  ## Writes `s` into the slice at the current cursor position using the current
  ## text attributes. The cursor position should be set relative to the slice.
  let pos = slice.getCursorPos()
  slice.write(pos, s)
