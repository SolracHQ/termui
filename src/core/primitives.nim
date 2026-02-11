type
  Size* = object
    ## Represents the size of a rectangular area, such as a terminal window or a UI component.
    width*, height*: int

  Position* = object
    ## Represents the position of a point in a 2D space, such as the coordinates of a UI component on the terminal.
    x*, y*: int

  Rect* = object
    ## Represents a rectangular area defined by its position and size. This can be used to define the boundaries of a UI component or a section of the terminal.
    pos*: Position
    size*: Size

proc contains*(r: Rect, p: Position): bool =
  ## Checks if the given position `p` is within the bounds of the rectangle `r`.
  let xInBounds = p.x >= r.pos.x and p.x < r.pos.x + r.size.width
  let yInBounds = p.y >= r.pos.y and p.y < r.pos.y + r.size.height
  return xInBounds and yInBounds
