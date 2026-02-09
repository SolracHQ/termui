import primitives
import illwill

type RenderContext* = object
  tb*: TerminalBuffer
  clipRect*: Rect
