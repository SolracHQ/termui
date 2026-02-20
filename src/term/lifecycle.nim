# Module to handle terminal initialization and deinitialization, as well as full-screen mode.

import ctx
import ../core/error

import std/[terminal]

import platform

when defined(posix):
  import std/os
  const
    XtermColor = "xterm-color"
    Xterm256Color = "xterm-256color"
else:
  import std/winlean

proc enterFullScreen() =
  ## Enters full-screen mode (clears the terminal).
  when defined(posix):
    case getEnv("TERM")
    of XtermColor:
      stdout.write "\e7\e[?47h"
    of Xterm256Color:
      stdout.write "\e[?1049h"
    else:
      eraseScreen()
  else:
    eraseScreen()

proc exitFullScreen() =
  ## Exits full-screen mode (restores the previous contents of the terminal).
  when defined(posix):
    case getEnv("TERM")
    of XtermColor:
      stdout.write "\e[2J\e[?47l\e8"
    of Xterm256Color:
      stdout.write "\e[?1049l"
    else:
      eraseScreen()
  else:
    eraseScreen()
    setCursorPos(0, 0)

proc termInit*(fullScreen: bool = true, mouse: bool = false) =
  ## Initializes the terminal and enables non-blocking keyboard input. Needs
  ## to be called before doing anything with the library.
  ##
  ## If `mouse` is set to `true`, mouse events are captured and returned
  ## as part of the Event union from `getEvent()`.
  ##
  ## If the module is already intialised, `TermError` is raised.
  if gTermCtx.initialized:
    raise newException(TermError, "Illwill already initialised")
  gTermCtx.fullScreen = fullScreen
  if gTermCtx.fullScreen:
    enterFullScreen()

  platform.consoleInit()
  gTermCtx.mouseEnabled = mouse
  if gTermCtx.mouseEnabled:
    when defined(posix):
      platform.enableMouse()
    else:
      platform.enableMouse(getStdHandle(STD_INPUT_HANDLE))
  gTermCtx.initialized = true
  resetAttributes()

proc termDeinit*() =
  ## Resets the terminal to its previous state. Needs to be called before
  ## exiting the application.
  ##
  ## If the module is not intialised, `TermError` is raised.
  checkInit()
  if gTermCtx.fullScreen:
    exitFullScreen()
  if gTermCtx.mouseEnabled:
    when defined(posix):
      platform.disableMouse()
    else:
      platform.disableMouse(
        getStdHandle(STD_INPUT_HANDLE), platform.gOldConsoleModeInput
      )
  platform.consoleDeinit()
  gTermCtx.initialized = false
  resetAttributes()
  showCursor()
