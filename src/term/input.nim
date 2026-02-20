## This module provide functions to get term events, like key presses and mouse events

when defined(windows):
  import input/windows
elif defined(posix):
  import input/unix
else:
  {.error, "Unsupported platform".}

import input/constants
import ctx

export constants

proc getEvent*(): Event =
  ## Reads the next keystroke or mouse event in a non-blocking manner.
  ## If there are no events in the buffer, an Event with kind ekNone is returned.
  ##
  ## If the module is not intialised, `TermError` is raised.
  checkInit()
  result = getEventAsync(0)

proc getEventWithTimeout*(ms = 1000): Event =
  ## Reads the next keystroke or mouse event with a timeout. If there were no events
  ## in the specified `ms` period, an Event with kind ekNone is returned.
  ##
  ## If the module is not intialised, `TermError` is raised.
  checkInit()
  result = getEventAsync(ms)
