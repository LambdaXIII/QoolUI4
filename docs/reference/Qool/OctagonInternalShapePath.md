# OctagonInternalShapePath

Octagon interior-fill shape path: draws the fill region of a `QoolBox`. It is a
`ShapePath` whose interior 8 points (`int*`) form a closed polygon, with all control
points delegated to a `QoolBoxShapeControl`. When the border width is greater than 0
the interior points shrink inward relative to the outer outline, so the fill region
does not intersect the border region.

This is an internal composition part for `QoolBox`; a host generally does not need to
instantiate it directly.

## Properties

- `control` (`QoolBoxShapeControl`): the octagon control-point computation source
  (coming from the host `QoolBox`'s `control`). The interior points are read from its
  `int*` properties.

## Signals

This type defines no additional signals. (It inherits the standard `ShapePath`/`Item`
signals.)

## Methods

This type defines no additional methods.

## Usage Example

This type is not a reusable component — it is an internal composition part used by
`QoolBox` (via `OctagonShape`). Host code normally configures the octagon through
`QoolBox` and its `settings`/`control` instead of instantiating the shape path
directly.
