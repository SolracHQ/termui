## Concrete implementations of SizeBound types.
##
## This module contains bound implementations (Unbounded, Bounded)
## that define min/max constraints for size specifications.

import ../core/constraints

type
  Unbounded* = ref object of SizeBound ## No limit on size

  Bounded* = ref object of SizeBound ## Specific size limit
    value*: int

# Constructors

proc unbounded*(): SizeBound =
  ## Create an unbounded size limit
  Unbounded()

proc bounded*(value: int): SizeBound =
  ## Create a bounded size limit
  Bounded(value: value)

# Method implementations

method applyBound*(bound: Unbounded, value: int): int =
  ## Unbounded applies no maximum constraint
  value

method applyBound*(bound: Bounded, value: int): int =
  ## Bounded applies maximum constraint
  min(value, bound.value)

method applyMinBound*(bound: Unbounded, value: int): int =
  ## Unbounded applies no minimum constraint
  value

method applyMinBound*(bound: Bounded, value: int): int =
  ## Bounded applies minimum constraint
  max(value, bound.value)
