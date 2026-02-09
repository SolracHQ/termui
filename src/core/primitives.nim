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
