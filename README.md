# TermUI

A simple DSL-based, widget-oriented TUI library for Nim. Think of it as something in the middle between illwill and ncurses, but with a declarative approach to building terminal interfaces.

## Status

This is a work in progress. The library is already capable of basic layouts and rendering, but several features are still missing:

- Event handling system
- Focus management
- Additional widgets (lists, dialogs, stack panels, etc.)

Right now I'm testing everything manually through the examples. The layout logic works and you can build simple interfaces, but there's plenty of room for improvement.

## Why TermUI?

I originally started this project for my own use in [StorageDetective](https://github.com/SolracHQ/StorageDetective). I wanted something more declarative than raw illwill but not as heavy as a full ncurses wrapper. The DSL approach makes it easier to reason about layouts without dealing with manual positioning and size calculations.

## Installation

Install directly from GitHub:

```
nimble install https://github.com/SolracHQ/termui
```

## Quick Example

Here's a simple example showing labels and text boxes:

```nim
import termui
import illwill
import std/os

import widgets/label
import layout/size_specs

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc main() =
  illwillInit(fullscreen = true)
  setControlCHook(exitProc)
  hideCursor()

  tui:
    with newLabel("Hello, World!", style = {styleBright}, fgColor = fgGreen)

    with newLabel(
      "This text will be truncated with ellipsis",
      width = fixed(20),
      overflowStrategy = osEllipsis,
      fgColor = fgYellow,
    )

  var key = getKey()
  while key != Key.Escape and key != Key.Q:
    sleep(20)
    key = getKey()

  exitProc()

when isMainModule:
  main()
```

## Available Widgets

- `label` - Single line text display with overflow strategies
- `textbox` - Multi-line text display
- `rect` - Colored rectangles for backgrounds or visual elements
- `hbox` - Horizontal layout container
- `vbox` - Vertical layout container (the default root container)
- `padding` - Add padding around child widgets

## Layout System

The layout system uses size specifications:

- `fill()` - Take all available space
- `flex(ratio)` - Take space proportional to the ratio (default is 1)
- `fixed(size)` - Use a fixed size in characters
- `content()` - Size based on content

Check out the colombian_flag.nim example to see flex ratios in action. It renders a flag using a 2:1:1 ratio for the colored sections.

## Running Examples

You can use the Justfile recipes to manage examples:

```
just list                    # List all available examples
just run colombian_flag      # Run a specific example
just run-all                 # Run all examples
just help                    # Show all available commands
```

Or run them manually:

```
nim r examples/colombian_flag.nim
nim r examples/simple_label.nim
```

## Testing

There are some tests for the layout system, but they are not comprehensive. You can run them with:

```
just test
```

## Contributing

I'm not an expert in TUI or UI development. I'm doing everything in a very artisanal way, learning as I go. If you know this stuff better than me and think you can improve things, feel free to open a PR. Just keep in mind this is a hobby project, so I might take a while to review it.

## License

MIT
