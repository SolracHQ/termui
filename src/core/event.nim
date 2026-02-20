import primitives

import std/options

type
  MouseButtonAction* = enum
    mbaPressed
    mbaReleased

  MouseButton* = enum
    mbLeft
    mbMiddle
    mbRight

  ScrollDirection* = enum
    sdUp
    sdDown

  EventModifier* = enum
    emNone
    emCtrl
    emShift

  KeyEvent* = object
    code*: int
    name*: string
    modifier*: EventModifier = emNone

  MouseMoveEvent* = object
    pos*: Position
    modifiers*: set[EventModifier]
    buttons*: set[MouseButton]

  MouseButtonEvent* = object
    pos*: Position
    button*: MouseButton
    action*: MouseButtonAction
    modifiers*: set[EventModifier]

  MouseScrollEvent* = object
    pos*: Position
    direction*: ScrollDirection
    modifiers*: set[EventModifier]

  EventKind* = enum
    ekNone
    ekKey
    ekMouseMove
    ekMouseButton
    ekMouseScroll
    ekUpdate
    ekResize
    ekFrameLag

  Event* = object
    case kind*: EventKind
    of ekKey:
      key*: KeyEvent
    of ekMouseMove:
      mouseMove*: MouseMoveEvent
    of ekMouseButton:
      mouseButton*: MouseButtonEvent
    of ekMouseScroll:
      mouseScroll*: MouseScrollEvent
    of ekFrameLag:
      lagMs*: int
    of ekResize:
      size*: Size
    of ekUpdate:
      delta*: float
    of ekNone:
      discard

proc isAnyKey*(e: Event, names: varargs[string]): bool =
  if e.kind != ekKey:
    return false
  for name in names:
    if e.key.name == name:
      return true
  false

proc isButtonPressed*(e: Event, buttons: set[MouseButton] = {mbLeft}): bool =
  if e.kind != ekMouseButton:
    return false
  e.mouseButton.action == mbaPressed and e.mouseButton.button in buttons

proc isButtonReleased*(e: Event, buttons: set[MouseButton] = {mbLeft}): bool =
  if e.kind != ekMouseButton:
    return false
  e.mouseButton.action == mbaReleased and e.mouseButton.button in buttons

proc isMouseMove*(e: Event): bool =
  e.kind == ekMouseMove

proc isMouseScroll*(e: Event): bool =
  e.kind == ekMouseScroll

proc isMouseScrollUp*(e: Event): bool =
  e.kind == ekMouseScroll and e.mouseScroll.direction == sdUp

proc isMouseScrollDown*(e: Event): bool =
  e.kind == ekMouseScroll and e.mouseScroll.direction == sdDown

proc isUpdate*(e: Event): bool =
  e.kind == ekUpdate

proc pos*(e: Event): Option[Position] =
  case e.kind
  of ekMouseMove:
    some(e.mouseMove.pos)
  of ekMouseButton:
    some(e.mouseButton.pos)
  of ekMouseScroll:
    some(e.mouseScroll.pos)
  else:
    none(Position)

import std/[strformat, strutils]

proc `$`*(m: MouseButton): string =
  case m
  of mbLeft: "Left"
  of mbMiddle: "Middle"
  of mbRight: "Right"

proc `$`*(a: MouseButtonAction): string =
  case a
  of mbaPressed: "Pressed"
  of mbaReleased: "Released"

proc `$`*(d: ScrollDirection): string =
  case d
  of sdUp: "Up"
  of sdDown: "Down"

proc `$`*(em: EventModifier): string =
  case em
  of emNone: ""
  of emCtrl: "Ctrl"
  of emShift: "Shift"

proc `$`*(mods: set[EventModifier]): string =
  var parts: seq[string]
  if emCtrl in mods:
    parts.add("Ctrl")
  if emShift in mods:
    parts.add("Shift")
  if parts.len == 0:
    ""
  else:
    parts.join("+")

proc `$`*(buttons: set[MouseButton]): string =
  var parts: seq[string]
  if mbLeft in buttons:
    parts.add("Left")
  if mbMiddle in buttons:
    parts.add("Middle")
  if mbRight in buttons:
    parts.add("Right")
  if parts.len == 0:
    ""
  else:
    parts.join("+")

proc `$`*(k: KeyEvent): string =
  case k.modifier
  of emCtrl:
    fmt"Ctrl+{k.name}"
  of emShift:
    fmt"Shift+{k.name}"
  else:
    k.name

proc `$`*(m: MouseMoveEvent): string =
  let modsStr =
    if m.modifiers != {}:
      $m.modifiers & "+"
    else:
      ""
  let buttonsStr =
    if m.buttons != {}:
      " [" & $m.buttons & "]"
    else:
      ""
  fmt"MouseMove({modsStr}{m.pos}{buttonsStr})"

proc `$`*(m: MouseButtonEvent): string =
  let modsStr =
    if m.modifiers != {}:
      $m.modifiers & "+"
    else:
      ""
  fmt"Mouse{$m.action}({modsStr}{$m.button} at {m.pos})"

proc `$`*(m: MouseScrollEvent): string =
  let modsStr =
    if m.modifiers != {}:
      $m.modifiers & "+"
    else:
      ""
  fmt"MouseScroll({modsStr}{$m.direction} at {m.pos})"

proc `$`*(e: Event): string =
  case e.kind
  of ekNone:
    "None"
  of ekKey:
    fmt"Key({$e.key})"
  of ekMouseMove:
    $e.mouseMove
  of ekMouseButton:
    $e.mouseButton
  of ekMouseScroll:
    $e.mouseScroll
  of ekFrameLag:
    fmt"FrameLag({e.lagMs}ms)"
  of ekUpdate:
    "Update"
  of ekResize:
    "Resize"
