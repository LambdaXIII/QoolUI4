# Crystal4ContainmentMask

A crystal-4 (diamond) shape `containmentMask`: a `QQuickItem` derived
mask with an O(1) numeric hit test.

`Crystal4ContainmentMask` is meant for the `containmentMask` property of
crystal-4-shaped components such as `ColorCrystal` and `ColorCursor`;
hosts generally do not need to instantiate it directly.

### v4 containmentMask pattern

`QQuickItem.containmentMask` requires a `QQuickItem`-derived type. In v3
this mask derived from `QObject` (host components bridged the test
themselves); in v4 it derives from `QQuickItem` and overrides
`QQuickItem::contains()`, so it can be assigned straight to a
`containmentMask` property and Qt performs the coordinate transforms
automatically. (The `Qool` module's `ShapeContainmentMask` has been
removed — those masks are carried directly by the controls; this
component is independent and unaffected.)

The point passed to `contains()` is in the mask's own local coordinate
system. When the mask is placed as a child of the host at (0, 0) with the
same size, mask-local and host-local coordinates coincide — both
`ColorCrystal` and `ColorCursor` use it that way.

### Hit test (formula reused verbatim from v3)

The hit test is a pure numeric inequality (Manhattan distance / L1 norm),
independent of path filling, with stable O(1) performance:

```
|x - cx| + |y - cy| * (h / w) <= w / 2
```

where `x`/`y` is the test point (mask-local), `cx`/`cy` is `centerPoint`,
and `w`/`h` are the mask's own `width`/`height` (the diamond's bounding
box, taken from the `QQuickItem` geometry). The formula and transform
order are reused verbatim from v3:

1. When `w != h`, `y` is pre-scaled by the `h / w` ratio (an affine
   transform);
2. When `centerPoint != (0, 0)`, the point is translated to the coordinate
   system centered on the diamond;
3. The Manhattan test `|x| + |y| <= w / 2` decides the hit, boundary
   inclusive.

Geometry: with `w == h` this is a regular diamond with vertices
(`±w/2`, 0), (0, `±h/2`); with `w != h` it is an affinely scaled diamond —
the horizontal half-width is always `w/2` and the vertical half-length is
always `w²/(2h)` (a result of the y pre-scaling, not `h/2` — do not
"fix" it by intuition).

### Common misunderstandings

- `width` / `height` come directly from the `QQuickItem` geometry (the
  diamond's bounding box), not from separate mask properties — this is the
  architectural decision of the v4 containmentMask pattern (the mask *is*
  a `QQuickItem`), not a lost API; the QML usage
  `width: parent.width` matches v3.
- The default `centerPoint` (0, 0) puts the diamond center at the mask
  origin — this is the inherited v3 semantics, not a defect
  (`ColorCrystal` relies on it).
- The order of the y pre-scaling and the translation in the formula must
  not be swapped (v3 fidelity; reordering changes the hit region).

## Properties

- `centerPoint : point` (default: `(0, 0)`)
  The diamond center in mask-local coordinates. With the default value the
  mask skips the translation branch and the diamond center sits at the
  mask's coordinate origin — `ColorCrystal` uses this default (its
  diamond is drawn around its own origin, so mask and shape naturally
  coincide); `ColorCursor` passes its own center point. Note this is a
  mask-local point, not a host coordinate: when the mask moves with its
  host, its local origin follows, so `centerPoint` does not need to track
  the host's displacement.

## Signals

- `centerPointChanged()`
  Emitted when `centerPoint` changes.

## Methods

This type defines no additional methods (the `contains()` override is a
C++ virtual, not invokable from QML).

## Usage Example

```qml
import QtQuick
import Qool.Color

Rectangle {
    width: 100
    height: 100

    containmentMask: Crystal4ContainmentMask {
        width: parent.width
        height: parent.height
        // centerPoint defaults to (0, 0): diamond centered at the origin
    }
}
```
