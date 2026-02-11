import unittest
import std/strutils
import core/[widget, primitives, constraints]
import widgets
import layout

suite "Label Layout Tests":
  test "Label measure with content size":
    let label = newLabel("Hello", width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = label.measure(available)

    # Label should prefer its text length
    check measureResult.preferred.width == 5 # "Hello" is 5 chars
    check measureResult.preferred.height == 1
    check measureResult.min.width == 1
    check measureResult.min.height == 1

  test "Label with fixed width":
    let label = newLabel("Test", width = fixed(20), height = fixed(1))

    let available = Size(width: 100, height: 50)
    let measureResult = label.measure(available)

    # Measure returns preferred based on content, but arrange should use constraint
    check measureResult.preferred.width == 4 # "Test" is 4 chars

    # Arrange with constraints
    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 10))
    discard label.arrange(rect)

    # After arrange, calculatedRect should match what was given
    check label.calculatedRect.size.width == 100
    check label.calculatedRect.size.height == 10

  test "Label arrange sets calculatedRect":
    let label = newLabel("World")

    let rect = Rect(pos: Position(x: 10, y: 20), size: Size(width: 30, height: 1))

    let result = label.arrange(rect)

    check result == arSuccess
    check label.calculatedRect.pos.x == 10
    check label.calculatedRect.pos.y == 20
    check label.calculatedRect.size.width == 30
    check label.calculatedRect.size.height == 1

  test "Label with text longer than width returns arClipped":
    let label = newLabel("This is a very long text", overflowStrategy = osClip)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 10, height: 1))

    let result = label.arrange(rect)

    # Text is 24 chars but width is 10, should be clipped
    check result == arClipped
    check label.calculatedRect.size.width == 10

  test "Label with text shorter than width returns arSuccess":
    let label = newLabel("Hi")

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 20, height: 1))

    let result = label.arrange(rect)

    check result == arSuccess

  test "Label with osError overflow strategy returns arTooSmall":
    let label = newLabel("Long text here", overflowStrategy = osError)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 5, height: 1))

    let result = label.arrange(rect)

    check result == arTooSmall

  test "Label with zero width returns arClipped":
    let label = newLabel("Text")

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 0, height: 1))

    let result = label.arrange(rect)

    check result == arClipped

  test "Label with zero height returns arClipped":
    let label = newLabel("Text")

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 10, height: 0))

    let result = label.arrange(rect)

    check result == arClipped

  test "Label with different overflow strategies":
    # osEllipsis
    let label1 = newLabel("Long text", overflowStrategy = osEllipsis)
    let rect1 = Rect(pos: Position(x: 0, y: 0), size: Size(width: 5, height: 1))
    let result1 = label1.arrange(rect1)
    check result1 == arClipped

    # osEllipsisMid
    let label2 = newLabel("Long text", overflowStrategy = osEllipsisMid)
    let rect2 = Rect(pos: Position(x: 0, y: 0), size: Size(width: 5, height: 1))
    let result2 = label2.arrange(rect2)
    check result2 == arClipped

    # osClip
    let label3 = newLabel("Long text", overflowStrategy = osClip)
    let rect3 = Rect(pos: Position(x: 0, y: 0), size: Size(width: 5, height: 1))
    let result3 = label3.arrange(rect3)
    check result3 == arClipped

  test "Label defaults":
    let label = newLabel("Test")

    # Check defaults
    check label.text == "Test"
    check label.overflowStrategy == osClip
    check label.fgColor == fgWhite
    check label.bgColor == bgBlack

    # Width and height should be set in constraints
    let available = Size(width: 100, height: 50)
    let measureResult = label.measure(available)
    check measureResult.preferred.height == 1 # Default height is fixed(1)

  test "Label with empty text":
    let label = newLabel("")

    let available = Size(width: 100, height: 50)
    let measureResult = label.measure(available)

    check measureResult.preferred.width == 0
    check measureResult.preferred.height == 1

  test "Label with long text":
    let longText = repeat("A", 100)
    let label = newLabel(longText)

    let available = Size(width: 200, height: 50)
    let measureResult = label.measure(available)

    check measureResult.preferred.width == 100
