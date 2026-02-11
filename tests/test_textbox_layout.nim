import unittest
import core/[widget, primitives, constraints]
import widgets
import layout
import std/strutils

suite "TextBox Layout Tests":
  test "TextBox measure with content size":
    let textbox =
      newTextBox(@["Line 1", "Line 2", "Line 3"], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    # TextBox should prefer width of longest line and height of line count
    check measureResult.preferred.width == 6 # "Line 1" and others are 6 chars
    check measureResult.preferred.height == 3 # 3 lines
    check measureResult.min.width == 1
    check measureResult.min.height == 1

  test "TextBox with varying line lengths":
    let textbox = newTextBox(
      @["Short", "This is a much longer line", "Med"],
      width = content(),
      height = content(),
    )

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    # Should prefer width of longest line
    check measureResult.preferred.width == 26 # "This is a much longer line"
    check measureResult.preferred.height == 3

  test "TextBox with fixed width and height":
    let textbox =
      newTextBox(@["Line 1", "Line 2"], width = fixed(30), height = fixed(10))

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    # Measure returns preferred based on content
    check measureResult.preferred.width == 6
    check measureResult.preferred.height == 2

    # Arrange should use the given size
    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))
    discard textbox.arrange(rect)

    check textbox.calculatedRect.size.width == 100
    check textbox.calculatedRect.size.height == 50

  test "TextBox arrange sets calculatedRect":
    let textbox = newTextBox(@["Hello", "World"])

    let rect = Rect(pos: Position(x: 10, y: 20), size: Size(width: 30, height: 5))

    let result = textbox.arrange(rect)

    check result == arSuccess
    check textbox.calculatedRect.pos.x == 10
    check textbox.calculatedRect.pos.y == 20
    check textbox.calculatedRect.size.width == 30
    check textbox.calculatedRect.size.height == 5

  test "TextBox with single line":
    let textbox = newTextBox(@["Only one line"], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    check measureResult.preferred.width == 13 # "Only one line"
    check measureResult.preferred.height == 1

  test "TextBox with empty lines":
    let textbox = newTextBox(@["", "Middle", ""], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    # Empty lines are 0 width, so longest is "Middle"
    check measureResult.preferred.width == 6
    check measureResult.preferred.height == 3

  test "TextBox with all empty lines":
    let textbox = newTextBox(@["", "", ""], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    check measureResult.preferred.width == 0
    check measureResult.preferred.height == 3

  test "TextBox with no lines":
    let textbox = newTextBox(@[], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    check measureResult.preferred.width == 0
    check measureResult.preferred.height == 0

  test "TextBox with many lines":
    var lines: seq[string] = @[]
    for i in 1 .. 50:
      lines.add("Line " & $i)

    let textbox = newTextBox(lines, width = content(), height = content())

    let available = Size(width: 100, height: 100)
    let measureResult = textbox.measure(available)

    # "Line 50" is 7 chars (longest)
    check measureResult.preferred.width == 7
    check measureResult.preferred.height == 50

  test "TextBox with very long single line":
    let longLine = "A".repeat 200
    let textbox = newTextBox(@[longLine], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    check measureResult.preferred.width == 200
    check measureResult.preferred.height == 1

  test "TextBox with fixed height smaller than line count":
    let textbox = newTextBox(
      @["Line 1", "Line 2", "Line 3", "Line 4", "Line 5"],
      width = content(),
      height = fixed(3),
    )

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 50, height: 3))
    let result = textbox.arrange(rect)

    # Has 5 lines but only 3 height - should clip
    check result == arClipped

  test "TextBox with zero width":
    let textbox = newTextBox(@["Text"])

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 0, height: 10))
    let result = textbox.arrange(rect)

    check result == arClipped

  test "TextBox with zero height":
    let textbox = newTextBox(@["Text"])

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 10, height: 0))
    let result = textbox.arrange(rect)

    check result == arClipped

  test "TextBox defaults":
    let textbox = newTextBox(@["Test"])

    check textbox.lines.len == 1
    check textbox.lines[0] == "Test"
    check textbox.fgColor == fgNone
    check textbox.bgColor == bgNone

  test "TextBox with colors":
    let textbox = newTextBox(@["Colored"], fgColor = fgYellow, bgColor = bgBlue)

    check textbox.fgColor == fgYellow
    check textbox.bgColor == bgBlue

  test "TextBox with style":
    let textbox = newTextBox(@["Styled"], style = {styleBright, styleItalic})

    check styleBright in textbox.style
    check styleItalic in textbox.style

  test "TextBox arrange with exact size for content":
    let textbox = newTextBox(@["ABC", "DEF"], width = fixed(3), height = fixed(2))

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 3, height: 2))
    let result = textbox.arrange(rect)

    # Exact fit should succeed
    check result == arSuccess

  test "TextBox with unicode characters in measure":
    # Note: This assumes single-width unicode chars for simplicity
    let textbox =
      newTextBox(@["Hello 🌍", "World"], width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    # Length may vary depending on how unicode is counted
    # Just verify it doesn't crash
    check measureResult.preferred.height == 2

  test "TextBox position from parent":
    let textbox = newTextBox(@["Positioned"])

    let rect = Rect(pos: Position(x: 50, y: 100), size: Size(width: 20, height: 5))
    discard textbox.arrange(rect)

    check textbox.calculatedRect.pos.x == 50
    check textbox.calculatedRect.pos.y == 100

  test "TextBox with fill size":
    let textbox = newTextBox(@["Fill"], width = fill(), height = fill())

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 80, height: 40))
    let result = textbox.arrange(rect)

    check result == arSuccess
    check textbox.calculatedRect.size.width == 80
    check textbox.calculatedRect.size.height == 40

  test "TextBox with mixed length lines":
    let textbox = newTextBox(
      @["A", "AB", "ABC", "ABCD", "ABCDE"], width = content(), height = content()
    )

    let available = Size(width: 100, height: 50)
    let measureResult = textbox.measure(available)

    check measureResult.preferred.width == 5 # "ABCDE" is longest
    check measureResult.preferred.height == 5
