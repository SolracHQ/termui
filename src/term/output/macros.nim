## Macro utilities for terminal output
## Provides special write macro for interspersing text with attribute commands

import types
import buffer
import std/macros
from std/terminal import Style

type TerminalCmd* = enum ## commands that can be expressed as arguments
  resetStyle ## reset attributes

template writeProcessArg(tb: var TerminalBuffer, s: string) =
  tb.write(s)

template writeProcessArg(tb: var TerminalBuffer, style: Style) =
  tb.setStyle({style})

template writeProcessArg(tb: var TerminalBuffer, style: set[Style]) =
  tb.setStyle(style)

template writeProcessArg(tb: var TerminalBuffer, color: ForegroundColor) =
  tb.setForegroundColor(color)

template writeProcessArg(tb: var TerminalBuffer, color: BackgroundColor) =
  tb.setBackgroundColor(color)

template writeProcessArg(tb: var TerminalBuffer, cmd: TerminalCmd) =
  when cmd == resetStyle:
    tb.resetAttributes()

macro write*(tb: var TerminalBuffer, args: varargs[typed]): untyped =
  ## Special version of `write` that allows to intersperse text literals with
  ## set attribute commands.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   import illwill
  ##
  ##   termInit(fullscreen=false)
  ##
  ##   var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  ##
  ##   tb.setForegroundColor(fgGreen)
  ##   tb.setBackgroundColor(bgBlue)
  ##   tb.write(0, 10, "before")
  ##
  ##   tb.write(0, 11, "unchanged", resetStyle, fgYellow, "yellow", bgRed, "red bg",
  ##                   styleBlink, "blink", resetStyle, "reset")
  ##
  ##   tb.write(0, 12, "after")
  ##
  ##   tb.display()
  ##
  ##   termDeinit()
  ##
  ## This will output the following:
  ##
  ## * 1st row:
  ##   - `before` with blue background, green foreground and default style
  ## * 2nd row:
  ##   - `unchanged` with blue background, green foreground and default style
  ##   - `yellow` with default background, yellow foreground and default style
  ##   - `red bg` with red background, yellow foreground and default style
  ##   - `blink` with red background, yellow foreground and blink style (if
  ##     supported by the terminal)
  ##   - `reset` with the default background and foreground and default style
  ## * 3rd row:
  ##   - `after` with the default background and foreground and default style
  ##
  ##
  result = newNimNode(nnkStmtList)

  if args.len >= 3 and args[0].typeKind() == ntyInt and args[1].typeKind() == ntyInt:
    let x = args[0]
    let y = args[1]
    result.add(newCall(bindSym"setCursorPos", tb, x, y))
    for i in 2 ..< args.len:
      let item = args[i]
      result.add(newCall(bindSym"writeProcessArg", tb, item))
  else:
    for item in args.items:
      result.add(newCall(bindSym"writeProcessArg", tb, item))
