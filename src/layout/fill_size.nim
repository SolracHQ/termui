## FillSize specification - fill all available space.
##
## This spec type defines a widget that fills all available space,
## with optional min/max bounds.

import ../core/constraints
import bounds

type FillSize* = ref object of SizeSpec
  minBound*: SizeBound
  maxBound*: SizeBound

# Constructor

proc fill*(minBound: SizeBound = nil, maxBound: SizeBound = nil): SizeSpec =
  ## Create a fill size specification
  FillSize(
    minBound:
      if minBound.isNil:
        unbounded()
      else:
        minBound,
    maxBound:
      if maxBound.isNil:
        unbounded()
      else:
        maxBound,
  )

# Method implementations

method resolve*(spec: FillSize, available: int, contentSize: int): int =
  ## Fill size uses all available space, clamped by bounds
  result = available
  result = spec.minBound.applyMinBound(result)
  result = spec.maxBound.applyBound(result)
