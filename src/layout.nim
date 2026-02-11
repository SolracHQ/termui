## Layout module with constructor helpers for size specifications and bounds.
##
## This module provides a clean API for creating size specs and bounds
## without needing to construct the case objects directly.

import core/constraints

export constraints

# SizeBound constructors

proc unbounded*(): SizeBound =
  ## Create an unbounded size limit
  SizeBound(kind: sbUnbounded)

proc bounded*(value: int): SizeBound =
  ## Create a bounded size limit
  SizeBound(kind: sbBounded, value: value)

# SizeSpec constructors

proc fixed*(size: int): SizeSpec =
  ## Create a fixed size specification
  SizeSpec(kind: ssFixed, size: size)

proc content*(
    minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a content-sized specification
  SizeSpec(
    kind: ssContent,
    contentMinBound: minBound,
    contentMaxBound: maxBound
  )

proc fill*(
    minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a fill size specification
  SizeSpec(
    kind: ssFill,
    fillMinBound: minBound,
    fillMaxBound: maxBound
  )

proc flex*(
    factor: FlexFactor,
    minBound: SizeBound = unbounded(),
    maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a flexible size specification with a specific factor
  SizeSpec(
    kind: ssFlex,
    factor: factor,
    flexMinBound: minBound,
    flexMaxBound: maxBound
  )

proc flex*(minBound: SizeBound = unbounded(), maxBound: SizeBound = unbounded()): SizeSpec =
  ## Create a flexible size specification with factor=1
  flex(1.FlexFactor, minBound, maxBound)

proc percent*(
    value: PercentValue,
    minBound: SizeBound = unbounded(),
    maxBound: SizeBound = unbounded()
): SizeSpec =
  ## Create a percentage size specification
  SizeSpec(
    kind: ssPercent,
    percent: value,
    percentMinBound: minBound,
    percentMaxBound: maxBound
  )
