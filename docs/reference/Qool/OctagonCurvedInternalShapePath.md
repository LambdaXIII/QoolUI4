# OctagonCurvedInternalShapePath

Octagon rounded interior-fill shape path. It is a `ShapePath` whose interior 8 points
(`int*`) form a closed ring (the fill region), with all control points delegated to a
`QoolBoxShapeControl` — the type holds no geometry. The inner arc radius is derived
from the inner-ring adjacent-point chord length divided by √2 (per-corner
independent; a degenerate chord of 0 yields a radius of 0).

This is an internal composition part for `QoolBox` (via `OctagonCurvedShape`); a host
generally does not need to instantiate it directly.

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
`QoolBox` (via `OctagonCurvedShape`). Host code normally configures the octagon
through `QoolBox` and its `settings`/`control` instead of instantiating the shape
path directly.
