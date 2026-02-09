## FixedSize specification - exact size constraint.
##
## This spec type defines a widget that has a fixed, exact size
## that doesn't change based on content or available space.

import ../core/constraints
import bounds

type FixedSize* = ref object of SizeSpec
  size*: int

# Constructor

proc fixed*(size: int): SizeSpec =
  ## Create a fixed size specification
  FixedSize(size: size)

# Method implementations

method resolve*(spec: FixedSize, available: int, contentSize: int): int =
  ## Fixed size always returns the exact size specified
  spec.size
