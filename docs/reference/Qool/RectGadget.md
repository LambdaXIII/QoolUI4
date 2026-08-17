# RectGadget

A rectangular-geometry gadget mounted under a standard `ShapeControl`. It provides
nine points, half-area rectangles, the inner maximum square, and related derived
geometry, plus precise hit testing.

`width`/`height` default-bind the `target` size (via `bindable_target`); `x`/`y`
default to `0` (they do not follow the target position — the derived geometry is
always in the local canvas coordinates, on the same baseline as rendering).
Explicitly setting `rect` (via `set_rect` → `setValue`) or directly binding
`x`/`y`/`width`/`height` in QML removes the corresponding construction binding,
making the geometry independent of the target — a deliberate design for canvas
chaining (for example `gB.rect = gA.maxInnerSquareRect` turns `gB` into an
independent canvas geometry source; `HalfCrystal` uses exactly this), not a defect.

`topHalfRect`/`bottomHalfRect`/`leftHalfRect`/`rightHalfRect` and
`maxInnerSquareRect` are derived from `rect` (the derived geometry is uniformly based
on the single `rect` data source — with no external binding, `rect` is just the
`x`/`y`/`width`/`height` assembly and the results are equivalent; when `rect` is
externally bound, the derived quantities follow the bound value, sharing the same
source as the `contains()` judgment domain). The coordinate baseline is this gadget's
local coordinates (starting at `x`/`y`; `0` by default, i.e. the target's internal
coordinate system) — during canvas chaining the mask coordinates share the same
baseline as rendering.

## Properties

- `x` / `y` (`real`): the rectangle's top-left position. Default `0` (do not follow
  the target).
- `width` / `height` (`real`): the rectangle's size. Default-bind the `target` size.
- `rect` (`rect`): the rectangle as a single data source. Set it (or bind
  `x`/`y`/`width`/`height`) to make the geometry independent of the target.

Nine points (each read-only `point` with `X`/`Y` components):

- `topLeft` / `topCenter` / `topRight` / `leftCenter` / `center` / `rightCenter` /
  `bottomLeft` / `bottomCenter` / `bottomRight`, with `topLeftX`/`topLeftY` (and so
  on).

Derived values:

- `halfWidth` / `halfHeight` (`real`): half the edge length (`rect.width / 2`,
  `rect.height / 2`).
- `shortEdge` / `longEdge` (`real`): `min`/`max` of the rectangle's width and height.
- `isSquare` (`bool`): `true` when the rectangle is square.
- `topHalfRect` / `bottomHalfRect` / `leftHalfRect` / `rightHalfRect` (`rect`): the
  four half-area rectangles.
- `maxInnerSquareRect` (`rect`): the maximum square centered on `rect` that fits
  inside it.
- `minOutterSquareRect` (`rect`): the minimum square centered on `rect` that
  contains it.

It also inherits `control` and `target` from `ShapeControlGadget`.

## Signals

This type defines no additional signals; each property has the auto-generated
`xxxChanged` signal.

## Methods

- `contains(point)` → `bool`: `true` when `point` lies inside the rectangle
  (`rect.contains`).
- `set_rect(rect)`: sets the rectangle (applies `x`/`y`/`width`/`height`).

## Usage Example

Used by `HalfCrystal` as the geometry source (`gA`, tracking the root size) and the
inner canvas (`gB = gA.maxInnerSquareRect`, with `x`/`y` fixed to 0, a one-step
`rect` binding in the root's internal coordinates):

```qml
import QtQuick
import Qool

Shape {
    id: root
    width: 40
    height: 40

    ShapeControl {
        id: ctrl
        RectGadget {
            id: gA
        }
        RectGadget {
            id: gB
            rect: gA.maxInnerSquareRect
        }
    }
}
```
