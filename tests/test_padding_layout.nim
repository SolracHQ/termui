import unittest
import core/[widget, primitives, constraints]
import widgets/[padding, label]
import layout/size_specs

suite "Padding Layout Tests":
  test "Padding with all sides equal":
    let padding = newPadding(
      width = content(), height = content(), left = 5, right = 5, top = 3, bottom = 3
    )

    let label = newLabel("Hello", width = fixed(20), height = fixed(1))
    padding.children.add(label)

    let available = Size(width: 100, height: 50)
    let measureResult = padding.measure(available)

    # Expected: child width (20) + left (5) + right (5) = 30
    # Expected: child height (1) + top (3) + bottom (3) = 7
    check measureResult.preferred.width == 30
    check measureResult.preferred.height == 7

  test "Padding arrange positions child correctly":
    let padding = newPadding(
      width = fixed(50), height = fixed(20), left = 4, right = 6, top = 2, bottom = 3
    )

    let label = newLabel("Test", width = fill(), height = fill())
    padding.children.add(label)

    let rect = Rect(pos: Position(x: 10, y: 20), size: Size(width: 50, height: 20))
    discard padding.arrange(rect)

    # Child should start at parent position + padding
    check label.calculatedRect.pos.x == 14 # 10 + 4 (left)
    check label.calculatedRect.pos.y == 22 # 20 + 2 (top)

    # Child size should be parent size - padding
    # Width: 50 - 4 (left) - 6 (right) = 40
    # Height: 20 - 2 (top) - 3 (bottom) = 15
    check label.calculatedRect.size.width == 40
    check label.calculatedRect.size.height == 15

  test "Padding with zero padding":
    let padding = newPadding(
      width = content(), height = content(), left = 0, right = 0, top = 0, bottom = 0
    )

    let label = newLabel("Text", width = fixed(10), height = fixed(2))
    padding.children.add(label)

    let available = Size(width: 100, height: 50)
    let measureResult = padding.measure(available)

    # No padding, so size should match child
    check measureResult.preferred.width == 10
    check measureResult.preferred.height == 2

  test "Padding with only left and right":
    let padding = newPadding(
      width = content(), height = content(), left = 10, right = 15, top = 0, bottom = 0
    )

    let label = newLabel("ABC", width = fixed(30), height = fixed(1))
    padding.children.add(label)

    let available = Size(width: 100, height: 50)
    let measureResult = padding.measure(available)

    # Width: 30 + 10 + 15 = 55
    # Height: 1 + 0 + 0 = 1
    check measureResult.preferred.width == 55
    check measureResult.preferred.height == 1

  test "Padding with only top and bottom":
    let padding = newPadding(
      width = content(), height = content(), left = 0, right = 0, top = 5, bottom = 7
    )

    let label = newLabel("XYZ", width = fixed(20), height = fixed(3))
    padding.children.add(label)

    let available = Size(width: 100, height: 50)
    let measureResult = padding.measure(available)

    # Width: 20 + 0 + 0 = 20
    # Height: 3 + 5 + 7 = 15
    check measureResult.preferred.width == 20
    check measureResult.preferred.height == 15

  test "Padding with fill width and height":
    let padding = newPadding(
      width = fill(), height = fill(), left = 2, right = 2, top = 1, bottom = 1
    )

    let label = newLabel("Content", width = fill(), height = fill())
    padding.children.add(label)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))
    discard padding.arrange(rect)

    # Padding's calculatedRect is determined by VBox arrange on inner rect
    # So it sizes to content (child + padding)
    check padding.calculatedRect.size.width == 96 # Inner rect width (100 - 2 - 2)
    check padding.calculatedRect.size.height == 48 # Inner rect height (50 - 1 - 1)

    # Child gets remaining space
    check label.calculatedRect.size.width == 96 # 100 - 2 - 2
    check label.calculatedRect.size.height == 48 # 50 - 1 - 1

  test "Padding with fixed child size":
    let padding = newPadding(
      width = content(), height = content(), left = 3, right = 3, top = 2, bottom = 2
    )

    let label = newLabel("Fixed", width = fixed(25), height = fixed(5))
    padding.children.add(label)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))
    discard padding.arrange(rect)

    # Check child received correct space
    check label.calculatedRect.size.width == 25
    check label.calculatedRect.size.height == 5

  test "Padding with content-sized child":
    let padding = newPadding(
      width = content(), height = content(), left = 1, right = 1, top = 1, bottom = 1
    )

    let label = newLabel("Hello World", width = content(), height = content())
    padding.children.add(label)

    let available = Size(width: 100, height: 50)
    let measureResult = padding.measure(available)

    # Child prefers its text length (11) + padding (1+1) = 13
    check measureResult.preferred.width == 13
    check measureResult.preferred.height == 3 # 1 (text) + 1 (top) + 1 (bottom)

  test "Padding without children":
    let padding = newPadding(
      width = content(), height = content(), left = 5, right = 5, top = 3, bottom = 3
    )

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 30, height: 20))
    let result = padding.arrange(rect)

    # Should succeed even without children
    check result == arSuccess
    # Padding arranges inner rect which has size (30-10) x (20-6) = 20x14
    check padding.calculatedRect.size.width == 20
    check padding.calculatedRect.size.height == 14

  test "Padding with asymmetric padding values":
    let padding = newPadding(
      width = content(), height = content(), left = 1, right = 10, top = 2, bottom = 20
    )

    let label = newLabel("Text", width = fixed(50), height = fixed(10))
    padding.children.add(label)

    let available = Size(width: 200, height: 100)
    let measureResult = padding.measure(available)

    # Width: 50 + 1 + 10 = 61
    # Height: 10 + 2 + 20 = 32
    check measureResult.preferred.width == 61
    check measureResult.preferred.height == 32

  test "Padding calculates correct inner rect position":
    let padding = newPadding(
      width = fixed(100),
      height = fixed(50),
      left = 15,
      right = 20,
      top = 8,
      bottom = 12,
    )

    let label = newLabel("Inner", width = fill(), height = fill())
    padding.children.add(label)

    let rect = Rect(pos: Position(x: 30, y: 40), size: Size(width: 100, height: 50))
    discard padding.arrange(rect)

    # Child starts at padding offset from parent position
    check label.calculatedRect.pos.x == 45 # 30 + 15
    check label.calculatedRect.pos.y == 48 # 40 + 8

    # Child size is parent size minus padding
    check label.calculatedRect.size.width == 65 # 100 - 15 - 20
    check label.calculatedRect.size.height == 30 # 50 - 8 - 12

  test "Padding with large padding values":
    let padding = newPadding(
      width = content(),
      height = content(),
      left = 50,
      right = 50,
      top = 50,
      bottom = 50,
    )

    let label = newLabel("X", width = content(), height = content())
    padding.children.add(label)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 20, height: 20))
    discard padding.arrange(rect)

    # Padding larger than available space - inner rect gets clamped to 0
    # Padding's calculatedRect becomes the inner rect size (0x0)
    check padding.calculatedRect.size.width == 0
    check padding.calculatedRect.size.height == 0
