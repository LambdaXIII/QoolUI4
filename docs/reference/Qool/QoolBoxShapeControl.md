# QoolBoxShapeControl

The octagon geometry unit: numeric control points, precise hit testing, and content
inset quantities. It is constructed by `QoolBox` by default and exposed as the
`control` property; it can also be instantiated standalone (as a low-level geometry
unit, used together with `OctagonShape`/`OctagonCurvedShape`). The geometry is
computed by two internal `QoolBoxGadget` instances (the `outer` outline and the
`inner` inset stroke ring) — this type only forwards and does not hold the algorithm.

## Properties

- `settings` (`QoolBoxSettings`): the appearance settings. When the instance is
  replaced, all gadget inputs are re-attached automatically; when `settings` is
  `null` the computation degenerates to `0` inputs (no crash). Reference semantics:
  a whole-set assignment shares the instance; an independent copy means assigning a
  new instance. `settings` is synchronized via signal connections, which
  automatically disconnect when `settings` is destroyed — a `settings` whose lifetime
  is shorter than this object is safe.

The control-point properties are read-only forwards of the gadget points, in the
target's internal coordinate system (absolute points including the center anchor and
`offset` translation):

- `extTL`…`extBR` (`point`): the 8 outer outline points, each with `extTLx`/`extTLy`
  (and so on) component properties.
- `intTL`…`intBR` (`point`): the 8 inner inset-ring points, each with `intTLx`/`intTLy`
  (and so on) component properties.

Naming convention: the first letter is the edge the point lies on, the second letter
is the endpoint position on that edge — `extTL` is the Top edge's Left endpoint,
`intLT` is the Left edge's Top endpoint. These are meant for self-drawing or
animating along the octagon.

Carried size and inset quantities:

- `usedWidth` / `usedHeight` (`real`, read-only): the actual carried size
  (`= max(expected size, diagonal cut sum)`, with the overflow semantics of
  `QoolBoxGadget`).
- `topSpace` / `bottomSpace` / `leftSpace` / `rightSpace` (`real`, read-only): the
  content-inset layout quantities, for host layout padding:
  `max(0, max(adjacent cut) − (used − expected)/2)`. When the `cut` hard parameters
  overflow, the content box is converted back from the `used` coordinate system to
  the expected one.

It also inherits the `ShapeControl` base properties (`target`, `x`, `y`, `width`,
`height`, `longEdge`, `shortEdge`, `aspectRatio`, `center`, `halfWidth`,
`halfHeight`, `boundingRect`).

## Signals

All properties notify through Qt's auto-generated `xxxChanged` signals, guarded so a
signal is emitted only when the actual value changes. This type defines no additional
signals.

## Methods

- `contains(point)` → `bool`: precisely tests whether `point` (local coordinates)
  hits the octagon, including the offset-translated judgment area. It delegates to
  the `outer` gadget's O(1) linear-inequality judgment and can be mounted directly as
  a `containmentMask` (a `QObject` mask).

## Usage Example

`QoolBox` uses this type internally as its `control`. It can also be used standalone
with a `OctagonShape`:

```qml
import QtQuick
import Qool

Item {
    id: box
    width: 200
    height: 120

    QoolBoxShapeControl {
        id: ctrl
        target: box
        settings: QoolBoxSettings {
            cutSizeTL: 20
            cutSizeTR: 20
            cutSizeBL: 20
            cutSizeBR: 20
            borderWidth: 2
            borderColor: "white"
            fillColor: "#20242b"
        }
    }
}
```
