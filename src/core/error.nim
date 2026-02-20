type
  TermUIError* = object of CatchableError ## Base error type for termui library

  TermError* = object of TermUIError
    ## Error type for general term errors, such as not being initialized

  OutOfBoundsError* = object of TermUIError
    ## Error type for when a widget tries to render outside of its allocated area
