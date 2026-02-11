import illwill

type
  EventKind* = enum
    evKey
    evMouse
    evResize # terminal size changed

  Event* = object
    case kind*: EventKind
    of evKey:
      key*: Key
    of evMouse:
      mouse*: MouseInfo
    of evResize:
      newWidth*: int
      newHeight*: int

  EventHandler* = proc(evt: Event): bool
    ## Returns true if event was handled (stops propagation)
