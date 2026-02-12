# TermUI

A simple DSL-based, widget-oriented TUI library for Nim. Think of it as something in the middle between illwill and ncurses, but with a declarative approach to building terminal interfaces.

## Status

This is a work in progress. The library is already capable of basic layouts, rendering, and event handling, but several features are still missing:

- Focus management
- Additional widgets (lists, dialogs, stack panels, etc.)
- Mouse event support (see Known Issues)

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
import widgets
import layout

proc main() =
  tui:
    with newLabel("Hello, World!", style = {styleBright}, fgColor = fgGreen)
    
    with newLabel(
      "This text will be truncated with ellipsis",
      width = fixed(20),
      overflowStrategy = osEllipsis,
      fgColor = fgYellow,
    )
    
    onEvent e:
      if e.kind == evKey and (e.key == Key.Escape or e.key == Key.Q):
        quit()

when isMainModule:
  main()
```

The `tui` macro handles all the boilerplate: illwill initialization, event loop, terminal cleanup, and Ctrl+C handling. You just write your UI declaratively.

## Composable Widgets

You can create reusable widget components using the `{.widget.}` pragma:

```nim
proc button(text: string, onClick: proc()) {.widget.} =
  with newPadding(width = content(), height = content(), left = 1, right = 1):
    with newLabel(text, fgColor = fgYellow, style = {styleBright}):
      onEvent e:
        if e.kind == evKey and e.key == Key.Enter:
          onClick()
          return true

proc counter(label: string, value: var int) {.widget.} =
  with newVBox(width = content(), height = content(), spacing = 1):
    with newLabel(label & ": " & $value, fgColor = fgCyan)
    
    with newHBox(width = content(), height = content(), spacing = 2):
      with button("[-]", proc() = value.dec())
      with button("[+]", proc() = value.inc())

# Use your widgets in the main app
proc main() =
  var count = 0
  
  tui:
    with counter("Count", count)
    
    with button("Reset", proc() = count = 0)
    
    onEvent e:
      if e.kind == evKey and e.key == Key.Escape:
        quit()
```

The `{.widget.}` pragma transforms your proc into a function that returns a `Widget`, allowing you to compose complex UIs from simple, reusable components. This solves the scoping issues of putting everything in one giant tui block.

## Event Handling

The library includes a built-in event system. You can handle events at any level of the widget tree using `onEvent`:

```nim
tui:
  with newLabel("Press ENTER"):
    onEvent e:
      if e.kind == evKey and e.key == Key.Enter:
        # Handle enter key
        return true  # Event consumed
  
  # Top-level event handler
  onEvent e:
    if e.kind == evKey and e.key == Key.Escape:
      quit()
```

Events bubble up from child widgets to parents. Return `true` from an event handler to stop propagation.

Available event types:
- `evKey` - Keyboard input
- `evMouse` - Mouse events (currently disabled, see Known Issues)
- `evResize` - Terminal resize
- `evUpdate` - Frame update (for animations)

## Lifecycle Hooks

You can use `onInit` and `onQuit` blocks for setup and cleanup:

```nim
tui:
  onInit:
    # Runs once before the event loop starts
    echo "Starting app..."
  
  with newLabel("My App")
  
  onQuit:
    # Runs after the event loop exits normally
    echo "Cleaning up..."
```

Note: `onInit` and `onQuit` only work at the top level of the `tui` block, not inside widget definitions.

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
nim r examples/widget_example.nim
```

## Testing

There are some tests for the layout system, but they are not comprehensive. You can run them with:

```
just test
```

## Known Issues

### Mouse Events (Currently Disabled)

Mouse event support is currently disabled due to issues in the underlying illwill library. The problem manifests as mouse escape sequences (like `\x1b[<35;39;10M`) not being properly parsed by illwill's `parseStdin` function. Instead of being recognized as mouse events, these sequences leak through as individual character keypresses (`Three`, `Five`, `Semicolon`, etc.), which floods the event loop and makes the application unresponsive.

This issue affects all platforms (Linux, Windows, WSL) and appears to be a fundamental limitation in illwill's event parsing logic, which hasn't been updated in over 4 years.

For now, the `tui` macro initializes illwill with `mouse = false`. Keyboard-based navigation works perfectly fine, and most TUI applications can be built effectively with just keyboard controls.

Future options being considered:
- Fix illwill's mouse parsing and contribute upstream
- Migrate to a more actively maintained library like notcurses or nimwave
- Implement custom mouse event parsing

Since the primary use case for this library is keyboard-driven interfaces, mouse support is not currently a priority. If you need mouse support, consider using one of the alternative libraries mentioned above.

## Contributing

I'm not an expert in TUI or UI development. I'm doing everything in a very artisanal way, learning as I go. If you know this stuff better than me and think you can improve things, feel free to open a PR. Just keep in mind this is a hobby project, so I might take a while to review it.

## License

MIT
