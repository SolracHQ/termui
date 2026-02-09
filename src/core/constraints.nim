## Core constraint types for termui layout engine.
##
## This module contains ONLY base types and method signatures.
## Concrete implementations are in layout/ modules.

type
  FlexFactor* = range[1 .. high(int)] ## Flex factor must be positive
  PercentValue* = range[0.0 .. 1.0] ## Percentage as a value between 0.0 and 1.0

  # Base types using inheritance
  SizeBound* = ref object of RootObj ## Base type for size bounds (min/max constraints)

  SizeSpec* = ref object of RootObj ## Base type for size specifications

  WidgetConstraints* = object ## Combined width and height specifications
    width*: SizeSpec
    height*: SizeSpec

  LayoutAxis* = enum
    ## Direction of layout
    laHorizontal
    laVertical

  LayoutMode* = enum
    ## How children are arranged
    lmStack ## Overlapping (z-order)
    lmBox ## Sequential along axis

  Alignment* = enum
    ## Alignment within available space
    alStart
    alCenter
    alEnd
    alStretch

# Base methods for SizeBound

method applyBound*(bound: SizeBound, value: int): int {.base.} =
  ## Apply a maximum bound constraint to a value
  raise newException(CatchableError, "applyBound not implemented for " & $bound.type)

method applyMinBound*(bound: SizeBound, value: int): int {.base.} =
  ## Apply a minimum bound constraint to a value
  raise newException(CatchableError, "applyMinBound not implemented for " & $bound.type)

# Base methods for SizeSpec resolution

method resolve*(spec: SizeSpec, available: int, contentSize: int): int {.base.} =
  ## Resolve a size spec to an actual size given available space and content size
  raise newException(CatchableError, "resolve not implemented for " & $spec.type)

method isFlex*(spec: SizeSpec): bool {.base.} =
  ## Check if this is a flex size spec
  false

method getFlexFactor*(spec: SizeSpec): FlexFactor {.base.} =
  ## Get the flex factor (only valid for FlexSize)
  raise newException(CatchableError, "getFlexFactor not implemented for " & $spec.type)

method resolveFlex*(
    spec: SizeSpec, flexSpace: int, totalFlexFactor: int
): int {.base.} =
  ## Resolve flex size given the available flex space and total flex factor
  raise newException(CatchableError, "resolveFlex not implemented for " & $spec.type)
