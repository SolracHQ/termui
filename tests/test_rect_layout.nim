import unittest
import core/[widget, primitives, constraints]
import widgets
import layout

suite "Rect Layout Tests":
  test "Rect measure with content size":
    let rect = newRect(width = content(), height = content())

    let available = Size(width: 100, height: 50)
    let measureResult = rect.measure(available)

    # Rect with content size has minimal preferred size
    check measureResult.preferred.width == 1
    check measureResult.preferred.height == 1
    check measureResult.min.width == 1
    check measureResult.min.height == 1

  test "Rect with fixed width and height":
    let rect = newRect(width = fixed(30), height = fixed(20))

    let available = Size(width: 100, height: 50)
    let measureResult = rect.measure(available)

    # Measure returns minimal preferred, but arrange should use constraint
    check measureResult.preferred.width == 1
    check measureResult.preferred.height == 1

    # Arrange should respect constraints
    let arrangeRect =
      Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))
    discard rect.arrange(arrangeRect)

    # calculatedRect should match what was given by arrange
    check rect.calculatedRect.size.width == 100
    check rect.calculatedRect.size.height == 50

  test "Rect arrange sets calculatedRect":
    let rect = newRect()

    let arrangeRect =
      Rect(pos: Position(x: 15, y: 25), size: Size(width: 40, height: 30))

    let result = rect.arrange(arrangeRect)

    check result == arSuccess
    check rect.calculatedRect.pos.x == 15
    check rect.calculatedRect.pos.y == 25
    check rect.calculatedRect.size.width == 40
    check rect.calculatedRect.size.height == 30

  test "Rect with zero width":
    let rect = newRect()

    let arrangeRect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 0, height: 10))

    let result = rect.arrange(arrangeRect)

    # Rect with zero width should be clipped
    check result == arClipped

  test "Rect with zero height":
    let rect = newRect()

    let arrangeRect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 10, height: 0))

    let result = rect.arrange(arrangeRect)

    # Rect with zero height should be clipped
    check result == arClipped

  test "Rect with both dimensions zero":
    let rect = newRect()

    let arrangeRect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 0, height: 0))

    let result = rect.arrange(arrangeRect)

    check result == arClipped

  test "Rect with background color":
    let rect = newRect(bgColor = bgRed)

    # Check that color is set
    check rect.bgColor == bgRed

  test "Rect defaults":
    let rect = newRect()

    # Check defaults
    check rect.bgColor == bgNone

  test "Rect with fill size":
    let rect = newRect(width = fill(), height = fill())

    let arrangeRect =
      Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))

    let result = rect.arrange(arrangeRect)

    check result == arSuccess
    check rect.calculatedRect.size.width == 100
    check rect.calculatedRect.size.height == 50

  test "Rect with flex size":
    let rect = newRect(width = flex(1), height = flex(2))

    # Flex rects need to be arranged by their parent
    # Just verify they can be measured
    let available = Size(width: 100, height: 50)
    let measureResult = rect.measure(available)

    check measureResult.preferred.width == 1
    check measureResult.preferred.height == 1

  test "Rect with large dimensions":
    let rect = newRect()

    let arrangeRect =
      Rect(pos: Position(x: 0, y: 0), size: Size(width: 1000, height: 1000))

    let result = rect.arrange(arrangeRect)

    check result == arSuccess
    check rect.calculatedRect.size.width == 1000
    check rect.calculatedRect.size.height == 1000

  test "Rect position offset":
    let rect = newRect()

    let arrangeRect =
      Rect(pos: Position(x: 100, y: 200), size: Size(width: 50, height: 50))

    discard rect.arrange(arrangeRect)

    check rect.calculatedRect.pos.x == 100
    check rect.calculatedRect.pos.y == 200

  test "Rect with different color values":
    let rect1 = newRect(bgColor = bgYellow)
    let rect2 = newRect(bgColor = bgCyan)
    let rect3 = newRect(bgColor = bgMagenta)

    check rect1.bgColor == bgYellow
    check rect2.bgColor == bgCyan
    check rect3.bgColor == bgMagenta

  test "Rect measure min size":
    let rect = newRect()

    let available = Size(width: 5, height: 3)
    let measureResult = rect.measure(available)

    # Min should always be 1x1
    check measureResult.min.width == 1
    check measureResult.min.height == 1

  test "Rect with content size measures to minimum":
    let rect = newRect(width = content(), height = content())

    let available = Size(width: 1000, height: 1000)
    let measureResult = rect.measure(available)

    # Content-sized rect prefers minimal size
    check measureResult.preferred.width == 1
    check measureResult.preferred.height == 1
