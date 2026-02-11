import primitives, constraints, context, event

type
  Widget* = ref object of RootObj
    ## Base type for all widgets. Contains common properties and methods.
    constraints*: WidgetConstraints
    calculatedRect*: Rect
    handler*: EventHandler

  Container* = ref object of Widget
    ## A container widget that can hold child widgets and manage their layout.
    children*: seq[Widget]
    alignment*: Alignment

  MeasureResult* = object
    min*: Size
    preferred*: Size

  ArrangeResult* = enum
    arSuccess # Widget fits
    arClipped # Widget partially fits (drawn clipped)
    arTooSmall # Widget cannot be drawn at all

# Base methods - all defined here with the types

method measure*(w: Widget, available: Size): MeasureResult {.base.} =
  ## Measure the widget given the available size, returning its minimum and preferred sizes.
  raise newException(CatchableError, "measure not implemented for " & $w.type)

method arrange*(w: Widget, rect: Rect): ArrangeResult {.base.} =
  ## Arrange the widget within the given rectangle.
  raise newException(CatchableError, "arrange not implemented for " & $w.type)

method render*(w: Widget, ctx: var RenderContext) {.base.} =
  ## Render the widget into the provided rendering context.
  raise newException(CatchableError, "render not implemented for " & $w.type)

method onEvent*(w: Widget, e: Event): bool {.base.} =
  ## Handle an event, returning true if the event was handled.
  raise newException(CatchableError, "onEvent not implemented for " & $w.type)

method onResize*(w: Container, e: Event): bool =
  if w.handler.isNil or w.handler(e):
    return true
  for child in w.children:
    if child.onResize(e):
      return true
  return false
