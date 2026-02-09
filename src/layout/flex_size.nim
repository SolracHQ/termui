## FlexSize specification - proportional flexible sizing.
##
## This spec type defines a widget that takes a proportional share
## of available space based on its flex factor, with optional min/max bounds.

import ../core/constraints
import bounds

type FlexSize* = ref object of SizeSpec
  factor*: FlexFactor
  minBound*: SizeBound
  maxBound*: SizeBound

# Constructors

proc flex*(
    factor: FlexFactor, minBound: SizeBound = nil, maxBound: SizeBound = nil
): SizeSpec =
  ## Create a flexible size specification with a specific factor
  FlexSize(
    factor: factor,
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

proc flex*(minBound: SizeBound = nil, maxBound: SizeBound = nil): SizeSpec =
  ## Create a flexible size specification with factor=1
  flex(1.FlexFactor, minBound, maxBound)

# Method implementations

method resolve*(spec: FlexSize, available: int, contentSize: int): int =
  ## Flex sizing needs special handling - return 0 as placeholder
  ## Actual resolution happens in resolveFlex
  0

method isFlex*(spec: FlexSize): bool =
  ## FlexSize is a flex spec
  true

method getFlexFactor*(spec: FlexSize): FlexFactor =
  ## Return the flex factor
  spec.factor

method resolveFlex*(spec: FlexSize, flexSpace: int, totalFlexFactor: int): int =
  ## Resolve flex size given available flex space and total flex factor
  result = (flexSpace * spec.factor) div totalFlexFactor
  result = spec.minBound.applyMinBound(result)
  result = spec.maxBound.applyBound(result)
