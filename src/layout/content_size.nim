## ContentSize specification - size based on content measurement.
##
## This spec type defines a widget that sizes itself based on its
## measured content, with optional min/max bounds.

import ../core/constraints
import bounds

type ContentSize* = ref object of SizeSpec
  minBound*: SizeBound
  maxBound*: SizeBound

# Constructor

proc content*(minBound: SizeBound = nil, maxBound: SizeBound = nil): SizeSpec =
  ## Create a content-sized specification
  ContentSize(
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

proc auto*(): SizeSpec =
  ## Auto-sized (content-based) specification - alias for content()
  content()

# Method implementations

method resolve*(spec: ContentSize, available: int, contentSize: int): int =
  ## Content size uses the measured content size, clamped by bounds
  result = contentSize
  result = spec.minBound.applyMinBound(result)
  result = spec.maxBound.applyBound(result)
