import unittest
import core/[widget, primitives, constraints]
import widgets
import containers
import layout

suite "VBox Layout Tests":
  test "VBox with fixed height children":
    # Create a VBox with 3 labels, each with fixed height
    let vbox = newVBox(width = content(), height = content(), spacing = 2)

    let label1 = newLabel("Hello", width = content(), height = fixed(3))
    let label2 = newLabel("World", width = content(), height = fixed(5))
    let label3 = newLabel("Test", width = content(), height = fixed(4))

    vbox.children.add(label1)
    vbox.children.add(label2)
    vbox.children.add(label3)

    # Measure with large available space
    let available = Size(width: 200, height: 50)
    let measureResult = vbox.measure(available)

    # Expected: 3 + 2 + 5 + 2 + 4 = 16 height
    check measureResult.preferred.height == 16

    # Arrange the VBox
    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 200, height: 50))

    discard vbox.arrange(rect)

    # Check that each child got the correct calculated rectangle
    echo "Label 1 rect: ", label1.calculatedRect
    echo "Label 2 rect: ", label2.calculatedRect
    echo "Label 3 rect: ", label3.calculatedRect

    check label1.calculatedRect.size.height == 3
    check label2.calculatedRect.size.height == 5
    check label3.calculatedRect.size.height == 4

    # Check positions (with spacing of 2)
    check label1.calculatedRect.pos.y == 0
    check label2.calculatedRect.pos.y == 5 # 3 + 2
    check label3.calculatedRect.pos.y == 12 # 3 + 2 + 5 + 2

  test "VBox with content height":
    # VBox should size to its children when using content()
    let vbox = newVBox(width = content(), height = content())

    let label1 = newLabel("ABC", height = fixed(3))
    let label2 = newLabel("DEF", height = fixed(7))

    vbox.children.add(label1)
    vbox.children.add(label2)

    let available = Size(width: 100, height: 100)
    let measureResult = vbox.measure(available)

    # Expected: 3 + 7 = 10 (no spacing)
    check measureResult.preferred.height == 10

  test "VBox with spacing":
    let vbox = newVBox(width = content(), height = content(), spacing = 3)

    let label1 = newLabel("A", height = fixed(5))
    let label2 = newLabel("B", height = fixed(5))
    let label3 = newLabel("C", height = fixed(5))

    vbox.children.add(label1)
    vbox.children.add(label2)
    vbox.children.add(label3)

    let available = Size(width: 100, height: 100)
    let measureResult = vbox.measure(available)

    # Expected: 5 + 3 + 5 + 3 + 5 = 21
    check measureResult.preferred.height == 21

  test "VBox arranges children with correct spacing":
    let vbox = newVBox(spacing = 4)

    let label1 = newLabel("X", height = fixed(6))
    let label2 = newLabel("Y", height = fixed(8))

    vbox.children.add(label1)
    vbox.children.add(label2)

    let rect = Rect(pos: Position(x: 10, y: 20), size: Size(width: 100, height: 100))

    discard vbox.arrange(rect)

    # First child starts at parent y
    check label1.calculatedRect.pos.y == 20
    check label1.calculatedRect.size.height == 6

    # Second child starts after first + spacing
    check label2.calculatedRect.pos.y == 30 # 20 + 6 + 4
    check label2.calculatedRect.size.height == 8

  test "VBox with flex children":
    let vbox = newVBox(width = content(), height = fill(), spacing = 0)

    let label1 = newLabel("Fixed", height = fixed(10))
    let label2 = newLabel("Flex1", height = flex(1))
    let label3 = newLabel("Flex2", height = flex(2))

    vbox.children.add(label1)
    vbox.children.add(label2)
    vbox.children.add(label3)

    # Arrange with 100 height total
    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 50, height: 100))

    discard vbox.arrange(rect)

    # Fixed takes 10, leaving 90 for flex
    # Flex ratio 1:2 means first gets 30, second gets 60
    check label1.calculatedRect.size.height == 10
    check label2.calculatedRect.size.height == 30
    check label3.calculatedRect.size.height == 60

  test "VBox alignment alCenter":
    let vbox = newVBox(width = fixed(100), height = content(), alignment = alCenter)

    let label1 = newLabel("Short", width = fixed(30))
    let label2 = newLabel("Medium text", width = fixed(50))

    vbox.children.add(label1)
    vbox.children.add(label2)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))

    discard vbox.arrange(rect)

    # Children should be centered horizontally
    check label1.calculatedRect.pos.x == 35 # (100 - 30) / 2
    check label2.calculatedRect.pos.x == 25 # (100 - 50) / 2

  test "VBox alignment alEnd":
    let vbox = newVBox(width = fixed(100), height = content(), alignment = alEnd)

    let label1 = newLabel("Text", width = fixed(40))

    vbox.children.add(label1)

    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 100, height: 50))

    discard vbox.arrange(rect)

    # Child should be aligned to the right
    check label1.calculatedRect.pos.x == 60 # 100 - 40

  test "VBox with mixed fixed and content heights":
    let vbox = newVBox(width = content(), height = content())

    let label1 = newLabel("ABC", height = fixed(10))
    let label2 = newLabel("DEF", height = content()) # Should use preferred (1 for label)

    vbox.children.add(label1)
    vbox.children.add(label2)

    let available = Size(width: 100, height: 100)
    let measureResult = vbox.measure(available)

    # Expected: 10 + 1 = 11
    check measureResult.preferred.height == 11
