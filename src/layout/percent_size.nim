## PercentSize specification - percentage of parent size.
##
## This spec type defines a widget that takes a percentage of the
## parent's available space, with optional min/max bounds.

import ../core/constraints
import bounds

type PercentSize* = ref object of SizeSpec
  percent*: PercentValue
  minBound*: SizeBound
  maxBound*: SizeBound

# Constructor

proc percent*(
    value: PercentValue, minBound: SizeBound = nil, maxBound: SizeBound = nil
): SizeSpec =
  ## Create a percentage size specification
  PercentSize(
    percent: value,
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

method resolve*(spec: PercentSize, available: int, contentSize: int): int =
  ## Percent size uses a percentage of available space, clamped by bounds
  result = int(float(available) * spec.percent)
  result = spec.minBound.applyMinBound(result)
  result = spec.maxBound.applyBound(result)
