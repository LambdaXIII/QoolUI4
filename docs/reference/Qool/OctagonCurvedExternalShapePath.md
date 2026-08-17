# OctagonCurvedExternalShapePath

Octagon rounded outer-outline shape path: draws the border-ring region of a `QoolBox`.
It is a `ShapePath` whose outer 8 points (`ext*`) and inner 8 points (`int*`) form a
closed ring (a double-ring hollowed stroke), with all control points delegated to a
`QoolBoxShapeControl` — the type holds no geometry. The outer arc radius equals the
corresponding corner `cut*` in `control.settings`; the inner arc radius is derived
from the inner-ring adjacent-point chord length divided by √2 (per-corner
independent; a degenerate chord of 0 yields a radius of 0). When the border width is 0
the outer and inner points coincide, the ring degenerates to zero area, and nothing is
drawn.

This is an internal composition part for `QoolBox` (via `OctagonCurvedShape`); a host
generally does not need to instantiate it directly.

## Properties

- `control` (`QoolBoxShapeControl`): the octagon control-point computation source
  (coming from the host `QoolBox`'s `control`). The ring points are read from its
  `ext*` and `int*` properties.

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
