from std/unicode import Rune
from std/terminal import Style
import ../../core/primitives

type
  ForegroundColor* = enum ## Foreground colors
    fgNone = 0 ## default
    fgBlack = 30 ## black
    fgRed ## red
    fgGreen ## green
    fgYellow ## yellow
    fgBlue ## blue
    fgMagenta ## magenta
    fgCyan ## cyan
    fgWhite ## white

  BackgroundColor* = enum ## Background colors
    bgNone = 0 ## default (transparent)
    bgBlack = 40 ## black
    bgRed ## red
    bgGreen ## green
    bgYellow ## yellow
    bgBlue ## blue
    bgMagenta ## magenta
    bgCyan ## cyan
    bgWhite ## white

  TerminalChar* = object
    ## Represents a character in the terminal buffer, including color and
    ## style information.
    ##
    ## If `forceWrite` is set to `true`, the character is always output even
    ## when double buffering is enabled (this is a hack to achieve better
    ## continuity of horizontal lines when using UTF-8 box drawing symbols in
    ## the Windows Console).
    ch*: Rune
    fg*: ForegroundColor
    bg*: BackgroundColor
    style*: set[Style]
    forceWrite*: bool

  TerminalBuffer* = ref object
    ## A virtual terminal buffer of a fixed width and height. It remembers the
    ## current color and style settings and the current cursor position.
    ##
    ## Write to the terminal buffer with `TerminalBuffer.write()` or access
    ## the character buffer directly with the index operators.
    width*: Natural
    height*: Natural
    buf*: seq[TerminalChar]
    currBg*: BackgroundColor
    currFg*: ForegroundColor
    currStyle*: set[Style]
    currX*: Natural
    currY*: Natural

  BoxChar* = int

  BoxBuffer* = ref object
    ## Box buffers are used to store the results of multiple consecutive box
    ## drawing calls. The idea is that when you draw a series of lines and
    ## rectangles into the buffer, the overlapping lines will get automatically
    ## connected by placing the appropriate UTF-8 symbols at the corner and
    ## junction points. The results can then be written to a terminal buffer.
    size*: Size
    buf*: seq[BoxChar]

proc termChar*(
    ch: Rune,
    fg: ForegroundColor = ForegroundColor.fgNone,
    bg: BackgroundColor = BackgroundColor.bgNone,
    style: set[Style] = {},
    forceWrite: bool = false,
): TerminalChar =
  ## Creates a new `TerminalChar` with the specified character, foreground color, background color, style, and forceWrite flag.
  return TerminalChar(ch: ch, fg: fg, bg: bg, style: style, forceWrite: forceWrite)

proc termChar*(
    ch: char,
    fg: ForegroundColor = ForegroundColor.fgNone,
    bg: BackgroundColor = BackgroundColor.bgNone,
    style: set[Style] = {},
    forceWrite: bool = false,
): TerminalChar =
  ## Overload of `termChar` that accepts a `char` instead of a `Rune`.
  return termChar(Rune(ch), fg, bg, style, forceWrite)
