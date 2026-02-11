import ../core/widget
import ../core/[primitives, context]
import illwill

proc getBoxColor(widget: Widget, depth: int): BackgroundColor =
  ## Get a background color for the widget based on depth
  let colors = [bgRed, bgGreen, bgYellow, bgBlue, bgMagenta, bgCyan]
  colors[depth mod colors.len]

proc fillBox(ctx: var RenderContext, rect: Rect, color: BackgroundColor) =
  ## Fill a rectangle with a solid color
  if rect.size.width < 1 or rect.size.height < 1:
    return

  ctx.tb.setBackgroundColor(color)

  # Fill the entire rectangle
  for y in 0 ..< rect.size.height:
    for x in 0 ..< rect.size.width:
      ctx.tb.write(rect.pos.x + x, rect.pos.y + y, " ")

  ctx.tb.resetAttributes()

proc renderBoxesImpl(widget: Widget, ctx: var RenderContext, depth: int = 0) =
  ## Internal implementation that tracks depth for coloring
  let rect = widget.calculatedRect
  let color = getBoxColor(widget, depth)

  fillBox(ctx, rect, color)

  # Recursively render children (they will draw on top)
  if widget of Container:
    let container = Container(widget)
    for child in container.children:
      renderBoxesImpl(child, ctx, depth + 1)

proc renderBoxes*(widget: Widget, ctx: var RenderContext) =
  ## Render debug boxes for all widgets in the tree
  ## This fills each widget's calculated rectangle with a solid color
  ## Different nesting levels get different colors
  renderBoxesImpl(widget, ctx, 0)
