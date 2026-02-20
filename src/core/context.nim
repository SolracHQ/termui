import primitives
import term/output/types

type
  RenderContext* = object
    slice*: TerminalSlice

  TerminalSlice* = object
    tb*: TerminalBuffer
    rect*: Rect
