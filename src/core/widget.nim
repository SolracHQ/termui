import primitives, constraints, context
import event
import hashes

type
  EventHandler* = proc(e: Event): bool

  Widget* = ref object of RootObj
    ## Base type for all widgets. Contains common properties and methods.
    constraints*: WidgetConstraints
    calculatedRect*: Rect
    handler*: EventHandler
    randomValue*: string

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
  if not w.handler.isNil:
    return w.handler(e)
  return false

method hash*(w: Widget): Hash {.base.} =
  ## Compute a hash for the widget, based on its type and properties.
  result =
    hash(w.randomValue) !& hash(w.constraints) !& hash(w.calculatedRect) !&
    hash(w.handler)
