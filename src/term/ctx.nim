## Term module Context global
import ../core/error

type TermContext* = object
  ## Terminal context that holds all state
  ## This replaces the global termState variable
  initialized*: bool
  mouseEnabled*: bool
  fullscreen*: bool
  fullRedrawNextFrame*: bool

var gTermCtx*: TermContext

proc checkInit*() =
  ## Checks if the terminal has been initialized
  ## Raises TermError if not initialized
  if not gTermCtx.initialized:
    raise newException(TermError, "Illwill not initialised")
