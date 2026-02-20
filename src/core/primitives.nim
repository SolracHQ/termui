type
  Size* = object
    ## Represents the size of a rectangular area, such as a terminal window or a UI component.
    width*, height*: Natural

  Position* = object
    ## Represents the position of a point in a 2D space, such as the coordinates of a UI component on the terminal.
    x*, y*: Natural

  Rect* = object
    ## Represents a rectangular area defined by its position and size. This can be used to define the boundaries of a UI component or a section of the terminal.
    pos*: Position
    size*: Size

proc size*(width: Natural = 0, height: Natural = width): Size =
  ## Creates a new `Size` object with the specified width and height.
  return Size(width: width, height: height)

proc position*(x: Natural = 0, y: Natural = x): Position =
  ## Creates a new `Position` object with the specified x and y coordinates.
  return Position(x: x, y: y)

proc rect*(pos: Position = position(), size: Size = size()): Rect =
  ## Creates a new `Rect` object with the specified position and size.
  return Rect(pos: pos, size: size)

proc rect*(x: Natural, y: Natural, width: Natural, height: Natural): Rect =
  ## Creates a new `Rect` object using the specified x and y coordinates for the position, and width and height for the size.
  return Rect(pos: position(x, y), size: size(width, height))

proc `$`*(p: Position): string =
  ## Returns a string representation of the position, showing its x and y coordinates.
  return "Position(x: " & $p.x & ", y: " & $p.y & ")"

proc `$`*(s: Size): string =
  ## Returns a string representation of the size, showing its width and height.
  return "Size(width: " & $s.width & ", height: " & $s.height & ")"

proc `$`*(r: Rect): string =
  ## Returns a string representation of the rectangle, showing its position and size.
  return "Rect(pos: " & $r.pos & ", size: " & $r.size & ")"

proc contains*(r: Rect, p: Position): bool =
  ## Checks if the given position `p` is within the bounds of the rectangle `r`.
  let xInBounds = p.x >= r.pos.x and p.x < r.pos.x + r.size.width
  let yInBounds = p.y >= r.pos.y and p.y < r.pos.y + r.size.height
  return xInBounds and yInBounds
