import ../core/constraints
import ../term
import std/hashes

type
  Alignment* = enum
    ## Alignment within available space
    alStart
    alCenter
    alEnd
    alStretch

  Padding* = object
    left*: Natural
    right*: Natural
    top*: Natural
    bottom*: Natural

  Modifier* = object # Border
    hasBorder*: bool = false
    doubleStyle*: bool = false
    # Padding
    padding*: Padding
    # Background
    hasBackground*: bool = false
    bgColor*: BackgroundColor = bgNone
    # Layout
    spacing*: Natural = 0
    alignment*: Alignment = alStart
    # Size
    width*: SizeSpec = content()
    height*: SizeSpec = content()

# Padding constructors
proc padding*(
    all: Natural = 0,
    vertical: Natural = if all > 0: all else: 0,
    horizontal: Natural = if all > 0: all else: 0,
    left: Natural = if horizontal > 0: horizontal else: 0,
    right: Natural = if horizontal > 0: horizontal else: 0,
    top: Natural = if vertical > 0: vertical else: 0,
    bottom: Natural = if vertical > 0: vertical else: 0,
): Padding =
  result.left = left
  result.right = right
  result.top = top
  result.bottom = bottom

proc horizontal*(p: Padding): Natural =
  p.left + p.right

proc vertical*(p: Padding): Natural =
  p.top + p.bottom

proc hash*(p: Padding): int =
  p.left.hash !& p.right.hash !& p.top.hash !& p.bottom.hash

# Modifier constructor
proc newModifier*(
    hasBorder: bool = false,
    doubleStyle: bool = false,
    padding: Padding = Padding(),
    hasBackground: bool = false,
    bgColor: BackgroundColor = bgNone,
    spacing: Natural = 0,
    alignment: Alignment = alStart,
    width: SizeSpec = content(),
    height: SizeSpec = content(),
): Modifier =
  result.hasBorder = hasBorder
  result.doubleStyle = doubleStyle
  result.padding = padding
  result.hasBackground = hasBackground
  result.bgColor = bgColor
  result.spacing = spacing
  result.alignment = alignment
  result.width = width
  result.height = height

# Functional modifier methods (mutating)
proc border*(m: var Modifier, doubleStyle: bool = false) =
  m.hasBorder = true
  m.doubleStyle = doubleStyle

proc padding*(m: var Modifier, all: Natural) =
  m.padding = padding(all = all)

proc padding*(
    m: var Modifier,
    left: Natural = 0,
    right: Natural = 0,
    top: Natural = 0,
    bottom: Natural = 0,
) =
  m.padding = Padding(left: left, right: right, top: top, bottom: bottom)

proc padding*(m: var Modifier, p: Padding) =
  m.padding = p

proc spacing*(m: var Modifier, spacing: Natural) =
  m.spacing = spacing

proc alignment*(m: var Modifier, alignment: Alignment) =
  m.alignment = alignment

proc background*(m: var Modifier, color: BackgroundColor) =
  m.hasBackground = true
  m.bgColor = color

proc width*(m: var Modifier, width: SizeSpec) =
  m.width = width

proc height*(m: var Modifier, height: SizeSpec) =
  m.height = height

proc size*(m: var Modifier, width: SizeSpec, height: SizeSpec = width) =
  m.width = width
  m.height = height

# Helper accessors
proc borderSize*(m: Modifier): Natural =
  if m.hasBorder: 2 else: 0

proc hash*(m: Modifier): int =
  return
    m.hasBorder.hash !& m.doubleStyle.hash !& m.padding.hash !& m.hasBackground.hash !&
    m.bgColor.hash !& m.spacing.hash !& m.alignment.hash !& m.width.hash !& m.height.hash
