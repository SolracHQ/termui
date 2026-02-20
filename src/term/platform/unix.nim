## Low-level Unix/POSIX console operations
## Handles console initialization, terminal mode management, and signal handlers

import std/[posix, termios, terminal]
import ../ctx

# Signal handlers for terminal control
# Adapted from:
# https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_chapter/libc_24.html#SEC499

proc kbhit*(ms: int): cint =
  ## Checks if keyboard input is available within the specified timeout
  var tv: Timeval
  tv.tv_sec = Time(ms div 1000)
  tv.tv_usec = 1000 * (int32(ms) mod 1000) # int32 because of macos

  var fds: TFdSet
  FD_ZERO(fds)
  FD_SET(STDIN_FILENO, fds)
  discard select(STDIN_FILENO + 1, fds.addr, nil, nil, tv.addr)
  return FD_ISSET(STDIN_FILENO, fds)

proc SIGTSTP_handler(sig: cint) {.noconv.} =
  signal(SIGTSTP, SIG_DFL)
  resetAttributes()
  showCursor()
  # consoleDeinit will be called
  discard posix.raise(SIGTSTP)

proc SIGCONT_handler(sig: cint) {.noconv.} =
  signal(SIGCONT, SIGCONT_handler)
  signal(SIGTSTP, SIGTSTP_handler)

  # Signal that a full redraw is needed
  gTermCtx.fullRedrawNextFrame = true
  hideCursor()

proc installSignalHandlers() =
  signal(SIGCONT, SIGCONT_handler)
  signal(SIGTSTP, SIGTSTP_handler)

proc nonblock(enabled: bool) =
  ## Enables or disables non-blocking mode for stdin
  var ttyState: Termios

  # get the terminal state
  discard tcGetAttr(STDIN_FILENO, ttyState.addr)

  if enabled:
    # turn off canonical mode & echo
    ttyState.c_lflag = ttyState.c_lflag and not Cflag(ICANON or ECHO)

    # minimum of number input read
    ttyState.c_cc[VMIN] = 0.char
  else:
    # turn on canonical mode & echo
    ttyState.c_lflag = ttyState.c_lflag or ICANON or ECHO

  # set the terminal attributes.
  discard tcSetAttr(STDIN_FILENO, TCSANOW, ttyState.addr)

proc consoleInit*() =
  ## Initializes the Unix console
  ## Sets non-blocking mode and installs signal handlers
  nonblock(true)
  installSignalHandlers()

proc consoleDeinit*() =
  ## Restores the console to blocking mode
  nonblock(false)

# Mouse support - ANSI escape sequences
# References:
# https://de.wikipedia.org/wiki/ANSI-Escapesequenz
# https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Extended-coordinates
const
  CSI* = 0x1B.chr & 0x5B.chr
  SET_BTN_EVENT_MOUSE = "1002"
  SET_ANY_EVENT_MOUSE = "1003"
  SET_SGR_EXT_MODE_MOUSE = "1006"
  ENABLE = "h"
  DISABLE = "l"

import std/strformat

proc enableMouse*() =
  ## Enables mouse tracking in the terminal
  const MouseTrackAny =
    fmt"{CSI}?{SET_BTN_EVENT_MOUSE}{ENABLE}{CSI}?{SET_ANY_EVENT_MOUSE}{ENABLE}{CSI}?{SET_SGR_EXT_MODE_MOUSE}{ENABLE}"
  stdout.write(MouseTrackAny)
  stdout.flushFile()

proc disableMouse*() =
  ## Disables mouse tracking in the terminal
  const DisableMouseTrackAny =
    fmt"{CSI}?{SET_BTN_EVENT_MOUSE}{DISABLE}{CSI}?{SET_ANY_EVENT_MOUSE}{DISABLE}{CSI}?{SET_SGR_EXT_MODE_MOUSE}{DISABLE}"
  stdout.write(DisableMouseTrackAny)
  stdout.flushFile()

template put*(s: string) =
  stdout.write s
