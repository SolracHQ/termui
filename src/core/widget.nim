import primitives, constraints, context, event

type
  Widget* = ref object of RootObj
    constraints*: WidgetConstraints
    calculatedRect*: Rect
    handler*: EventHandler

  Container* = ref object of Widget
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
