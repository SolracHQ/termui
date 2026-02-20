## Windows-specific input event reading
## Handles keyboard and mouse event parsing for Windows console

import constants

import std/[winlean, bitops, options]

type LastMouseState = object
  x*: int
  y*: int
  button*: Option[MouseButton]

var gLastMouseInfo: LastMouseState

# Console event type constants
const
  KEY_EVENT = 0x0001
  MOUSE_EVENT = 0x0002
  WINDOW_BUFFER_SIZE_EVENT = 0x0004
  MENU_EVENT = 0x0008
  FOCUS_EVENT = 0x0010

# Mouse event constants
const
  FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001
  FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004
  RIGHTMOST_BUTTON_PRESSED = 0x0002
  LEFT_CTRL_PRESSED = 0x0008
  RIGHT_CTRL_PRESSED = 0x0004
  SHIFT_PRESSED = 0x0010
  MOUSE_WHEELED = 0x0004

const INPUT_BUFFER_LEN = 512

# Windows console input structures
type
  WCHAR = WinChar
  CHAR = char
  BOOL = WINBOOL
  WORD = uint16
  UINT = cint
  SHORT = int16

  KEY_EVENT_RECORD_UNION* {.bycopy, union.} = object
    UnicodeChar*: WCHAR
    AsciiChar*: CHAR

  KEY_EVENT_RECORD* {.bycopy.} = object
    bKeyDown*: BOOL
    wRepeatCount*: WORD
    wVirtualKeyCode*: WORD
    wVirtualScanCode*: WORD
    uChar*: KEY_EVENT_RECORD_UNION
    dwControlKeyState*: DWORD

  COORD* {.bycopy.} = object
    X*: SHORT
    Y*: SHORT

  PCOORD* = ptr COORD

  FOCUS_EVENT_RECORD* {.bycopy.} = object
    bSetFocus*: BOOL

  MENU_EVENT_RECORD* {.bycopy.} = object
    dwCommandId*: UINT

  PMENU_EVENT_RECORD* = ptr MENU_EVENT_RECORD

  MOUSE_EVENT_RECORD* {.bycopy.} = object
    dwMousePosition*: COORD
    dwButtonState*: DWORD
    dwControlKeyState*: DWORD
    dwEventFlags*: DWORD

  WINDOW_BUFFER_SIZE_RECORD* {.bycopy.} = object
    dwSize*: COORD

  INPUT_RECORD_UNION* {.bycopy, union.} = object
    KeyEvent*: KEY_EVENT_RECORD
    MouseEvent*: MOUSE_EVENT_RECORD
    WindowBufferSizeEvent*: WINDOW_BUFFER_SIZE_RECORD
    MenuEvent*: MENU_EVENT_RECORD
    FocusEvent*: FOCUS_EVENT_RECORD

  INPUT_RECORD* {.bycopy.} = object
    EventType*: WORD
    Event*: INPUT_RECORD_UNION

  PINPUT_RECORD = ptr array[INPUT_BUFFER_LEN, INPUT_RECORD]
  LPDWORD = PDWORD

template alias(newName: untyped, call: untyped) =
  template newName(): untyped =
    call

proc parseWindowsMouseEvent(inputRecord: INPUT_RECORD): Event =
  ## Parses Windows mouse events into our Event type
  alias(me, inputRecord.Event.MouseEvent)

  let x = me.dwMousePosition.X
  let y = me.dwMousePosition.Y

  let ctrl = (
    bitand(me.dwControlKeyState, LEFT_CTRL_PRESSED) == LEFT_CTRL_PRESSED or
    bitand(me.dwControlKeyState, RIGHT_CTRL_PRESSED) == RIGHT_CTRL_PRESSED
  )
  let shift = bitand(me.dwControlKeyState, SHIFT_PRESSED) == SHIFT_PRESSED

  var modifiers: set[EventModifier] = {}
  if ctrl:
    modifiers.incl(emCtrl)
  if shift:
    modifiers.incl(emShift)

  # Check for scroll event
  if bitand(me.dwEventFlags, MOUSE_WHEELED) == MOUSE_WHEELED:
    let scrollDir =
      if me.dwButtonState.testBit(31): ScrollDirection.sdDown else: ScrollDirection.sdUp
    gLastMouseInfo = LastMouseState(x: x, y: y)
    return
      event(MouseScrollEvent(x: x, y: y, direction: scrollDir, modifiers: modifiers))

  # Determine button
  var button = none(MouseButton)
  case me.dwButtonState
  of FROM_LEFT_1ST_BUTTON_PRESSED:
    button = some(mbLeft)
  of FROM_LEFT_2ND_BUTTON_PRESSED:
    button = some(mbMiddle)
  of RIGHTMOST_BUTTON_PRESSED:
    button = some(mbRight)
  else:
    button = none(MouseButton)

  # Check for move event
  let isMove = (gLastMouseInfo.x != x or gLastMouseInfo.y != y)

  # Handle button press
  if button.isSome:
    gLastMouseInfo = LastMouseState(x: x, y: y, button: button)
    if isMove:
      # Dragging with button pressed
      var buttons: set[MouseButton] = {}
      buttons.incl(button.get)
      return event(MouseMoveEvent(x: x, y: y, modifiers: modifiers, buttons: buttons))
    else:
      # Button press
      return event(
        MouseButtonEvent(
          x: x, y: y, button: button.get, action: mbaPressed, modifiers: modifiers
        )
      )

  # Handle button release
  elif button.isNone and gLastMouseInfo.button.isSome:
    let releasedButton = gLastMouseInfo.button.get
    gLastMouseInfo = LastMouseState(x: x, y: y)
    return event(
      MouseButtonEvent(
        x: x, y: y, button: releasedButton, action: mbaReleased, modifiers: modifiers
      )
    )

  # Handle move without buttons
  elif isMove:
    gLastMouseInfo = LastMouseState(x: x, y: y)
    return event(MouseMoveEvent(x: x, y: y, modifiers: modifiers, buttons: {}))

  # No event
  else:
    return Event(kind: ekNone)

proc parseWindowsKeyEvent(keyEvent: KEY_EVENT_RECORD): Event =
  ## Parses Windows keyboard events into our Event type
  # Access UnicodeChar from the union
  let charCode = ord(keyEvent.uChar.UnicodeChar)

  if charCode != 0:
    return toKey(charCode)
  else:
    # Fall back to virtual scan code for special keys
    case keyEvent.wVirtualScanCode
    of 8:
      return Backspace
    of 9:
      return Tab
    of 13:
      return Enter
    of 32:
      return Space
    of 59:
      return F1
    of 60:
      return F2
    of 61:
      return F3
    of 62:
      return F4
    of 63:
      return F5
    of 64:
      return F6
    of 65:
      return F7
    of 66:
      return F8
    of 67:
      return F9
    of 68:
      return F10
    of 71:
      return Home
    of 72:
      return Up
    of 73:
      return PageUp
    of 75:
      return Left
    of 77:
      return Right
    of 79:
      return End
    of 80:
      return Down
    of 81:
      return PageDown
    of 82:
      return Insert
    of 83:
      return Delete
    of 87:
      return F11
    of 88:
      return F12
    else:
      return None

proc getEventAsync*(ms: int): Event =
  ## Unified event reader - handles all console events properly
  let fd = getStdHandle(STD_INPUT_HANDLE)
  var inputRecord: INPUT_RECORD
  var numRead: DWORD

  while true:
    case waitForSingleObject(fd, ms.int32)
    of WAIT_TIMEOUT:
      return Event(kind: ekNone)
    of WAIT_OBJECT_0:
      doAssert(readConsoleInput(fd, addr(inputRecord), 1, addr(numRead)) != 0)

      if numRead == 0:
        continue

      # Dispatch based on event type
      case inputRecord.EventType
      of KEY_EVENT:
        let keyEvent = inputRecord.Event.KeyEvent
        if keyEvent.bKeyDown == 0:
          # Key up event, ignore and continue reading
          continue
        return parseWindowsKeyEvent(keyEvent)
      of MOUSE_EVENT:
        return parseWindowsMouseEvent(inputRecord)
      of WINDOW_BUFFER_SIZE_EVENT:
        # todo: handle terminal resize?
        discard
        continue
      of MENU_EVENT:
        # Used internally by Windows, ignore
        discard
        continue
      of FOCUS_EVENT:
        # todo: handle focus in/out events?
        discard
        continue
      else:
        # Unknown event type, ignore
        discard
        continue
    else:
      doAssert(false, "Unexpected wait result")
