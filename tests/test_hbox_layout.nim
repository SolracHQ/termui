import unittest
import core/[widget, primitives, constraints]
import widgets/[hbox, label]
import layout/size_specs

suite "HBox Layout Tests":
  test "HBox with fixed width children":
    # Create an HBox with 3 labels, each with fixed width
    let hbox = newHBox(width = content(), height = content(), spacing = 2)

    let label1 = newLabel("Hello", width = fixed(20), height = fixed(1))
    let label2 = newLabel("World", width = fixed(30), height = fixed(1))
    let label3 = newLabel("Test", width = fixed(20), height = fixed(1))

    hbox.children.add(label1)
    hbox.children.add(label2)
    hbox.children.add(label3)

    # Measure with large available space
    let available = Size(width: 200, height: 50)
    let measureResult = hbox.measure(available)

    # Expected: 20 + 2 + 30 + 2 + 20 = 74 width
    check measureResult.preferred.width == 74
    check measureResult.preferred.height == 1

    # Arrange the HBox
    let rect = Rect(pos: Position(x: 0, y: 0), size: Size(width: 200, height: 10))

    discard hbox.arrange(rect)

    # Check that each child got the correct calculated rectangle
    echo "Label 1 rect: ", label1.calculatedRect
    echo "Label 2 rect: ", label2.calculatedRect
    echo "Label 3 rect: ", label3.calculatedRect

    check label1.calculatedRect.size.width == 20
    check label2.calculatedRect.size.width == 30
    check label3.calculatedRect.size.width == 20

    # Check positions (with spacing of 2)
    check label1.calculatedRect.pos.x == 0
    check label2.calculatedRect.pos.x == 22 # 20 + 2
    check label3.calculatedRect.pos.x == 54 # 20 + 2 + 30 + 2

  test "HBox with content width":
    # HBox should size to its children when using content()
    let hbox = newHBox(width = content(), height = content())

    let label1 = newLabel("ABC", width = fixed(10))
    let label2 = newLabel("DEF", width = fixed(15))

    hbox.children.add(label1)
    hbox.children.add(label2)

    let available = Size(width: 100, height: 50)
    let measureResult = hbox.measure(available)

    # Expected: 10 + 15 = 25 (no spacing)
    check measureResult.preferred.width == 25

  test "HBox with spacing":
    let hbox = newHBox(width = content(), height = content(), spacing = 5)

    let label1 = newLabel("A", width = fixed(10))
    let label2 = newLabel("B", width = fixed(10))
    let label3 = newLabel("C", width = fixed(10))

    hbox.children.add(label1)
    hbox.children.add(label2)
    hbox.children.add(label3)

    let available = Size(width: 100, height: 50)
    let measureResult = hbox.measure(available)

    # Expected: 10 + 5 + 10 + 5 + 10 = 40
    check measureResult.preferred.width == 40

  test "HBox arranges children with correct spacing":
    let hbox = newHBox(spacing = 3)

    let label1 = newLabel("X", width = fixed(5))
    let label2 = newLabel("Y", width = fixed(7))

    hbox.children.add(label1)
    hbox.children.add(label2)

    let rect = Rect(pos: Position(x: 10, y: 20), size: Size(width: 100, height: 10))

    discard hbox.arrange(rect)

    # First child starts at parent x
    check label1.calculatedRect.pos.x == 10
    check label1.calculatedRect.size.width == 5

    # Second child starts after first + spacing
    check label2.calculatedRect.pos.x == 18 # 10 + 5 + 3
    check label2.calculatedRect.size.width == 7
