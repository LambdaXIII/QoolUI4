# ShapeControl

The shape-control-point calculator base class in the Qool shape system (deriving from
`SmartObject`). It binds the geometry of a `target` (`QQuickItem`) and derives basic
geometry quantities: long edge, short edge, aspect ratio, center, half width/height,
and the bounding rectangle. Concrete shapes (such as `QoolBoxShapeControl`'s octagon)
compute their control points on top of these. A gadget mounts below this type,
associated via `control`, sharing the same target geometry.

## Coordinate-system semantics

`x`/`y` and `width`/`height` directly bind the corresponding properties of `target`.
Here `width`/`height` are the target's size, while `x`/`y` are the target's
displacement (position) in its parent's coordinate system.

The convention is that all shape geometry quantities are computed in the target's
internal coordinate system (origin at the target's top-left, range `0..width` /
`0..height`). Therefore `center`, `halfWidth`, `halfHeight`, and subclass control
points (such as `QoolBoxShapeControl`'s `ext*`/`int*`) do not include the `x`/`y`
offset. If you expect a `ShapeControl` to use the target's internal coordinate
system, you should not consume `x`/`y` — they describe the target's position in its
parent's coordinate system and are unrelated to internal coordinates. `boundingRect`
is the only derived quantity that merges `x`/`y` (the parent-coordinate bounding
rectangle), used by the base `contains()` fallback.

## Properties

- `target` (`Item`): the geometry source item. Defaults to the parent object (set
  automatically at `componentComplete`); an explicit assignment (including `null`)
  overrides the default. When `target` is `null`, `x`/`y` are 0 and `width`/`height`
  are 0, and the derived quantities degenerate accordingly.
- `x` (`real`, read-only): the target's horizontal displacement (position) in its
  parent's coordinate system, following `target.x`. `0` when `target` is `null`. Note
  the coordinate caveat above — it participates only in `boundingRect`.
- `y` (`real`, read-only): the target's vertical displacement (position) in its
  parent's coordinate system, following `target.y`. `0` when `target` is `null`. Same
  caveat as `x`.
- `width` (`real`, read-only): the target width, following `target.width`; `0` when
  `target` is `null`. It is the horizontal extent of the internal coordinate system.
- `height` (`real`, read-only): the target height, following `target.height`; `0`
  when `target` is `null`. It is the vertical extent of the internal coordinate
  system.
- `longEdge` (`real`, read-only): `max(width, height)`.
- `shortEdge` (`real`, read-only): `min(width, height)`.
- `aspectRatio` (`real`, read-only): `width / height`; `-1` when `height` is `0`.
- `center` (`point`, read-only): `(halfWidth, halfHeight)` — in the target's internal
  coordinate system, without the `x`/`y` offset.
- `halfWidth` (`real`, read-only): `width / 2`.
- `halfHeight` (`real`, read-only): `height / 2`.
- `boundingRect` (`rect`, read-only): `(x, y, width, height)` — parent coordinates.
  The only derived quantity merging `x`/`y`; used by the base `contains()` fallback.

## Signals

All properties notify through Qt's auto-generated `xxxChanged` signals, guarded so
that a signal is emitted only when the actual value changes. `ShapeControl` itself
defines no additional signals.

## Methods

- `contains(point)` → `bool`: determines whether `point` (local coordinates) lies
  inside the shape. The base implementation judges by the bounding rectangle; shape
  subclasses override it for exact judgment (for example `QoolBoxShapeControl`'s
  octagon linear inequality). This is the hit-testing extension point: a C++ extension
  subclasses this class (or `ShapeControlGadget`).
- `dumpInfo()`: prints debug diagnostics (`target` and `boundingRect`).

## Usage Example

`ShapeControl` is the geometry base; in QML it is normally consumed through its
concrete subclass `QoolBoxShapeControl`. Standalone use requires a `target`:

```qml
import QtQuick
import Qool

Item {
    id: box
    width: 200
    height: 120

    ShapeControl {
        target: box
    }
}
```
