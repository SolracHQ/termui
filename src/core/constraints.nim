## Core constraint types for termui layout engine.
##
## This module defines size specifications and bounds using case objects
## instead of inheritance for better performance and simpler code.

type
  FlexFactor* = range[1 .. high(int)] ## Flex factor must be positive
  PercentValue* = range[0.0 .. 1.0] ## Percentage as a value between 0.0 and 1.0

  SizeBoundKind* = enum
    sbUnbounded
    sbBounded

  SizeBound* = object
    case kind*: SizeBoundKind
    of sbUnbounded:
      discard
    of sbBounded:
      value*: int

  SizeSpecKind* = enum
    ssFixed
    ssContent
    ssFill
    ssFlex
    ssPercent

  SizeSpec* = object
    case kind*: SizeSpecKind
    of ssFixed:
      size*: int
    of ssContent:
      contentMinBound*: SizeBound
      contentMaxBound*: SizeBound
    of ssFill:
      fillMinBound*: SizeBound
      fillMaxBound*: SizeBound
    of ssFlex:
      factor*: FlexFactor
      flexMinBound*: SizeBound
      flexMaxBound*: SizeBound
    of ssPercent:
      percent*: PercentValue
      percentMinBound*: SizeBound
      percentMaxBound*: SizeBound

  WidgetConstraints* = object ## Combined width and height specifications
    width*: SizeSpec
    height*: SizeSpec

  Alignment* = enum
    ## Alignment within available space
    alStart
    alCenter
    alEnd
    alStretch

# SizeBound operations

proc applyBound*(bound: SizeBound, value: int): int =
  ## Apply a maximum bound constraint to a value
  case bound.kind
  of sbUnbounded:
    value
  of sbBounded:
    min(value, bound.value)

proc applyMinBound*(bound: SizeBound, value: int): int =
  ## Apply a minimum bound constraint to a value
  case bound.kind
  of sbUnbounded:
    value
  of sbBounded:
    max(value, bound.value)

# SizeSpec operations

proc resolve*(spec: SizeSpec, available: int, contentSize: int): int =
  ## Resolve a size spec to an actual size given available space and content size
  case spec.kind
  of ssFixed:
    result = spec.size
  of ssContent:
    result = contentSize
    result = spec.contentMinBound.applyMinBound(result)
    result = spec.contentMaxBound.applyBound(result)
  of ssFill:
    result = available
    result = spec.fillMinBound.applyMinBound(result)
    result = spec.fillMaxBound.applyBound(result)
  of ssFlex:
    result = 0 # Placeholder, actual resolution happens in resolveFlex
  of ssPercent:
    result = int(float(available) * spec.percent)
    result = spec.percentMinBound.applyMinBound(result)
    result = spec.percentMaxBound.applyBound(result)

proc isFlex*(spec: SizeSpec): bool =
  ## Check if this is a flex size spec
  spec.kind == ssFlex

proc getFlexFactor*(spec: SizeSpec): FlexFactor =
  ## Get the flex factor (only valid for FlexSize)
  spec.factor

proc resolveFlex*(spec: SizeSpec, flexSpace: int, totalFlexFactor: int): int =
  ## Resolve flex size given the available flex space and total flex factor
  result = (flexSpace * spec.factor) div totalFlexFactor
  result = spec.flexMinBound.applyMinBound(result)
  result = spec.flexMaxBound.applyBound(result)
