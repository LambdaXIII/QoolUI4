# HalfCrystal

A triangle variant of the `Crystal` color tile, built on the four-point model: the
`direction` property switches the pointing (`Qore.N`/`S`/`W`/`E` produce a right
isosceles triangle; any other value shows a full diamond — the default form). It is a
`Shape` component.

The four-point model takes the midpoints of the four edges of the inner maximum
square (45° hypotenuse, axis-aligned, canvas-centered): the outer four points are
`{(cx, north), (east, cy), (cx, south), (west, cy)}`. `direction` moves the opposite
point to the center (collinear, hidden at the base midpoint); the intermediate state
is always a diamond. Any `width`/`height` is safe, since the triangle is based on the
inner maximum square, centered. The default logical size is `20 × 20` (explicit
`width`/`height`).

## Properties

- `color` (`color`): the fill color. Default `Style.accent` (self-consistent default
  for standalone use).
- `borderColor` (`color`): the inner stroke-ring color. Default is an automatic
  contrast against the fill color via `ThemeHQ.recommendForeground`.
- `borderWidth` (`real`): the inner stroke-ring width. Default `1` — the outer
  outline shrinks inward by `borderWidth` to form the ring (entirely on the inside:
  no stroke protrudes past the outer outline, and the fill region shrinks by
  `borderWidth`). A `borderWidth < 1` disables the stroke — treated as 0, leaving a
  solid fill. The inset varies linearly with `borderWidth` (no shrink-limit clamp).
  The visual difference versus a single-layer center stroke is on the order of
  0.5 px.
- `fillGradient` (`Gradient`): the gradient fill channel. Default `null` (solid
  color); `fillItem` takes priority.
- `fillItem` (`Item`): the texture fill channel, with the same semantics as `Crystal`
  (priority over gradient/solid). No built-in gradient logic.
- `direction` (`int`, `Qore.Directions`): the pointing. `N`/`S`/`W`/`E` produce a
  right isosceles triangle (the opposite point moves to the center, the base being the
  remaining three points, and the right-angle apex lies on the pointing side); any
  other value (`Unknown`, or the diagonal `NW`/`NE`/`SW`/`SE`) shows a full diamond
  (all four points in place — the default state). Default `Qore.N`.

Rendering uses `preferredRendererType: Shape.CurveRenderer` (anti-aliased curves).

## Signals

This type defines no additional signals. (It inherits the standard `Shape`/`Item`
signals.)

## Methods

This type defines no additional methods.

## Animation

`HalfCrystal` provides no direction-switch animation — the `states` apply the form
directly (the intermediate state is always a diamond), and size changes jump
directly as well.

## Hit mask

The `containmentMask` is the inner-canvas rectangle (`RectGadget`, a numeric
rectangle `contains` judgment, not a `FillContains` path-fill judgment — controllable
performance cost). Hits are the inner-canvas rectangle region (the strips outside the
triangle are excluded; exact triangle judgment is not provided, since `RectGadget`
only has rectangle `contains`). Because Qt's hover dispatch only checks an item's own
`contains` (not ancestor masks), a host `MouseArea` must mount
`containmentMask: 组件id.containmentMask` to obtain precise hover (with
`anchors.fill` the local coordinates coincide with the component).

## Layout and implicit size

The explicit default `width`/`height` are `20` (the `Shape` engine forces
`setImplicitSize(path bounds)` on path change, overwriting any implicit declaration;
explicit sizes are not touched — same mechanism as `Crystal`). In the triangle form
the engine's implicit size is the path bounds (for example `N` state is `20 × 10`, a
half component) — implicit size is not promised, so layout always uses explicit
sizes. A host may override `width`/`height` normally.

## Usage Example

```qml
import QtQuick
import QtQuick.Shapes
import Qool

HalfCrystal {
    width: 40
    height: 40
    color: "#ff7a4a"
    direction: Qore.E
}
```
