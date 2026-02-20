## Unix/POSIX-specific input event reading
## Handles keyboard and mouse event parsing for Unix terminals

import constants
import ../platform

import std/[posix, tables, strutils, options, bitops]

# Key mapping tables
const
  KEYS_D = [Up, Down, Right, Left, None, End, None, Home]
  KEYS_E = [Delete, End, PageUp, PageDown, Home, End]
  KEYS_F = [F1, F2, F3, F4, F5, None, F6, F7, F8]
  KEYS_G = [F9, F10, None, F11, F12]

# Surely a 100 char buffer is more than enough; the longest
# keycode sequence I've seen was 6 chars
const KeySequenceMaxLen = 100

# Global keycode buffer
var keyBuf {.threadvar.}: array[KeySequenceMaxLen, char]

proc splitInputs(
    inp: openarray[char], max: Natural
): (seq[seq[char]], MouseButtonAction) =
  ## Splits the input buffer to extract mouse coordinates and button action
  var parts: seq[seq[char]] = @[]
  var cur: seq[char] = @[]
  var action = mbaPressed
  for ch in inp[CSI.len + 1 .. max - 1]:
    if ch == 'M':
      # Button press
      parts.add(cur)
      action = mbaPressed
      break
    elif ch == 'm':
      # Button release
      parts.add(cur)
      action = mbaReleased
      break
    elif ch != ';':
      cur.add(ch)
    else:
      parts.add(cur)
      cur = @[]
  return (parts, action)

proc getPos(inp: seq[char]): int =
  var str = ""
  for ch in inp:
    str &= ch
  result = parseInt(str)

proc parseMouseEvent(keyBuf: openArray[char]): Event =
  ## Parses ANSI mouse event sequences into our Event type
  let (parts, action) = splitInputs(keyBuf, keyBuf.len)
  let x = parts[1].getPos() - 1
  let y = parts[2].getPos() - 1

  let bitset = parts[0].getPos()
  let ctrl = bitset.testBit(4)
  let shift = bitset.testBit(2)
  let isMove = bitset.testBit(5)
  let isScroll = bitset.testBit(6)

  var modifiers: set[EventModifier] = {}
  if ctrl:
    modifiers.incl(emCtrl)
  if shift:
    modifiers.incl(emShift)

  # Check for scroll event first
  if isScroll:
    let scrollDir =
      if bitset.testBit(0): ScrollDirection.sdDown else: ScrollDirection.sdUp
    return event(
      MouseScrollEvent(pos: position(x, y), direction: scrollDir, modifiers: modifiers)
    )

  # Determine button
  var button = MouseButton.none()
  let buttonBits = ((bitset.uint8 shl 6) shr 6).int
  case buttonBits
  of 0:
    button = MouseButton.mbLeft.some()
  of 1:
    button = MouseButton.mbMiddle.some()
  of 2:
    button = MouseButton.mbRight.some()
  else:
    button = MouseButton.none()

  # Check if this is a move event
  if isMove:
    var buttons: set[MouseButton] = {}
    if button.isSome:
      buttons.incl(button.get)
    return
      event(MouseMoveEvent(pos: position(x, y), modifiers: modifiers, buttons: buttons))

  if button.isNone:
    # If no button is pressed, treat it as a move event
    return event(MouseMoveEvent(pos: position(x, y), modifiers: modifiers, buttons: {}))

  # Regular button event
  return event(
    MouseButtonEvent(
      pos: position(x, y), button: button.get, action: action, modifiers: modifiers
    )
  )

proc parseStdin[T](input: T): Event =
  ## Parses stdin input into keyboard or mouse events
  result = None
  if read(input, keyBuf[0].addr, 1) > 0:
    case keyBuf[0]
    of '\e':
      if read(input, keyBuf[1].addr, 1) > 0:
        if keyBuf[1] == 'O' and read(input, keyBuf[2].addr, 1) > 0:
          if keyBuf[2] in "ABCDFH":
            result = KEYS_D[int(keyBuf[2]) - int('A')]
          elif keyBuf[2] in "PQRS":
            result = KEYS_F[int(keyBuf[2]) - int('P')]
        elif keyBuf[1] == '[' and read(input, keyBuf[2].addr, 1) > 0:
          if keyBuf[2] == '<':
            for i in 3 .. KeySequenceMaxLen - 1:
              if read(input, keyBuf[i].addr, 1) <= 0:
                break
              if keyBuf[i] == 'M' or keyBuf[i] == 'm':
                result = parseMouseEvent(keyBuf[0 .. i])
                break
          elif keyBuf[2] in "ABCDFH":
            result = KEYS_D[int(keyBuf[2]) - int('A')]
          elif keyBuf[2] in "PQRS":
            result = KEYS_F[int(keyBuf[2]) - int('P')]
          elif keyBuf[2] == '1' and read(input, keyBuf[3].addr, 1) > 0:
            if keyBuf[3] == '~':
              result = Home
            elif keyBuf[3] in "12345789" and read(input, keyBuf[4].addr, 1) > 0 and
                keyBuf[4] == '~':
              result = KEYS_F[int(keyBuf[3]) - int('1')]
          elif keyBuf[2] == '2' and read(input, keyBuf[3].addr, 1) > 0:
            if keyBuf[3] == '~':
              result = Insert
            elif keyBuf[3] in "0134" and read(input, keyBuf[4].addr, 1) > 0 and
                keyBuf[4] == '~':
              result = KEYS_G[int(keyBuf[3]) - int('0')]
          elif keyBuf[2] in "345678" and read(input, keyBuf[3].addr, 1) > 0 and
              keyBuf[3] == '~':
            result = KEYS_E[int(keyBuf[2]) - int('3')]
          else:
            discard # if cannot parse full seq it is discarded
        else:
          discard # if cannot parse full seq it is discarded
      else:
        result = Escape
    of '\n':
      result = Enter
    of '\b':
      result = Backspace
    else:
      result = toKey(int(keyBuf[0]))

proc getEventAsync*(ms: int): Event =
  ## Reads keyboard or mouse events asynchronously with timeout
  result = Event(kind: ekNone)
  if kbhit(ms) > 0:
    result = parseStdin(cint(STDIN_FILENO))
