import illwill

type
  EventKind* = enum
    evKey
    evMouse
      ## illwill mouse events are completely broken, so this is not currently used. TODO: fix or migrate to another library.
    evResize # terminal size changed
    evUpdate # sent each frame

  Event* = object
    case kind*: EventKind
    of evKey:
      key*: Key
    of evMouse:
      # mouse*: MouseInfo
      discard
    of evResize:
      newWidth*: int
      newHeight*: int
    of evUpdate:
      delta*: float ## time since last update in seconds

  EventHandler* = proc(evt: Event): bool {.closure.}
    ## Returns true if event was handled (stops propagation)
