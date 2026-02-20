## Core constraint types for termui layout engine.
##
## This module defines size specifications and bounds using case objects
## instead of inheritance for better performance and simpler code.
import std/hashes

type
  FlexFactor* = Natural
  PercentValue* = range[0.0 .. 1.0] ## Percentage as a value between 0.0 and 1.0

  SizeBoundKind* = enum
    sbUnbounded
    sbBounded

  SizeBound* = object
    case kind*: SizeBoundKind
    of sbUnbounded:
      discard
    of sbBounded:
      value*: Natural

  SizeSpecKind* = enum
    ssFixed
    ssContent
    ssFill
    ssFlex
    ssPercent

  SizeSpec* = object
    case kind*: SizeSpecKind
    of ssFixed:
      size*: Natural
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

# SizeBound constructors

proc unbounded*(): SizeBound =
  ## Create an unbounded size limit
  SizeBound(kind: sbUnbounded)

proc bounded*(value: Natural): SizeBound =
  ## Create a bounded size limit
  SizeBound(kind: sbBounded, value: value)

# SizeSpec constructors

proc fixed*(size: Natural): SizeSpec =
  ## Create a fixed size specification
  SizeSpec(kind: ssFixed, size: size)

proc content*(
    minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a content-sized specification
  SizeSpec(kind: ssContent, contentMinBound: minBound, contentMaxBound: maxBound)

proc fill*(
    minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a fill size specification
  SizeSpec(kind: ssFill, fillMinBound: minBound, fillMaxBound: maxBound)

proc flex*(
    factor: FlexFactor,
    minBound: SizeBound = unbounded(),
    maxBound: SizeBound = unbounded(),
): SizeSpec =
  ## Create a flexible size specification with a specific factor
  SizeSpec(kind: ssFlex, factor: factor, flexMinBound: minBound, flexMaxBound: maxBound)

proc flex*(
    minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a flexible size specification with factor=1
  flex(1.FlexFactor, minBound, maxBound)

proc percent*(
    value: PercentValue,
    minBound: SizeBound = unbounded(),
    maxBound: SizeBound = unbounded(),
): SizeSpec =
  ## Create a percentage size specification
  SizeSpec(
    kind: ssPercent,
    percent: value,
    percentMinBound: minBound,
    percentMaxBound: maxBound,
  )

# SizeBound operations

proc applyBound*(bound: SizeBound, value: Natural): Natural =
  ## Apply a maximum bound constraint to a value
  case bound.kind
  of sbUnbounded:
    value
  of sbBounded:
    min(value, bound.value)

proc applyMinBound*(bound: SizeBound, value: Natural): Natural =
  ## Apply a minimum bound constraint to a value
  case bound.kind
  of sbUnbounded:
    value
  of sbBounded:
    max(value, bound.value)

# SizeSpec operations

proc resolve*(spec: SizeSpec, available: Natural, contentSize: Natural): Natural =
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
    result = Natural(float(available) * spec.percent)
    result = spec.percentMinBound.applyMinBound(result)
    result = spec.percentMaxBound.applyBound(result)

proc isFlex*(spec: SizeSpec): bool =
  ## Check if this is a flex size spec
  spec.kind == ssFlex

proc getFlexFactor*(spec: SizeSpec): FlexFactor =
  ## Get the flex factor (only valid for FlexSize)
  spec.factor

proc resolveFlex*(
    spec: SizeSpec, flexSpace: Natural, totalFlexFactor: Natural
): Natural =
  ## Resolve flex size given the available flex space and total flex factor
  result = (flexSpace * spec.factor) div totalFlexFactor
  result = spec.flexMinBound.applyMinBound(result)
  result = spec.flexMaxBound.applyBound(result)

proc hash*(spec: SizeSpec): Hash =
  ## Compute a hash for a SizeSpec based on its kind and parameters
  case spec.kind
  of ssFixed:
    result = hash(spec.size)
  of ssContent:
    result = hash(spec.contentMinBound) !& hash(spec.contentMaxBound)
  of ssFill:
    result = hash(spec.fillMinBound) !& hash(spec.fillMaxBound)
  of ssFlex:
    result = hash(spec.factor) !& hash(spec.flexMinBound) !& hash(spec.flexMaxBound)
  of ssPercent:
    result =
      hash(spec.percent) !& hash(spec.percentMinBound) !& hash(spec.percentMaxBound)

proc hash*(constraints: WidgetConstraints): Hash =
  ## Compute a hash for WidgetConstraints based on width and height specs
  result = constraints.width.hash() !& constraints.height.hash()
