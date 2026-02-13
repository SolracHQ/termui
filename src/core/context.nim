import primitives
import term

type RenderContext* = object
  tb*: TerminalBuffer
  clipRect*: Rect
