# Crystal

A crystal (octagon) color tile built on the eight-point model: with `width > height`
it is a hexagon, with `width = height` a diamond (a 45°-rotated square), and with
`width < height` a thin hexagon (pointed top/bottom with straight left/right sides).
It is top-left anchored.

`Crystal` is an `OctagonShape` specialization: it internally instantiates a
`QoolBoxShapeControl` (with `target` set to itself) whose settings bind all four
corner cuts to `shortEdge / 2` (a single-point definition through an internal
intermediate quantity — the eight-point geometry contract). The `borderWidth`
(default 1) produces an inset stroke ring. The three forms are the
`QoolBoxGadget` `cut = shortEdge / 2` specialization; under the half-plane
intersection model the degenerate forms (diamond, thin hexagon) are legal,
well-defined limits.

## Properties

- `color` (`color`): the fill color. Default `Style.accent` (self-consistent default
  for standalone use).
- `borderColor` (`color`): the inner stroke-ring color. Default is an automatic
  contrast against the fill color via `ThemeHQ.recommendForeground`.
- `borderWidth` (`real`): the inner stroke-ring width. Default `1` — the outer
  outline shrinks inward by `borderWidth` to form the ring (entirely on the inside:
  no stroke protrudes past the outer outline, and the fill region shrinks by
  `borderWidth`).
- `fillGradient` (alias, `ShapeGradient`) and `fillItem` (alias, `Item`): the fill
  channels, with the same semantics as `OctagonShape` — `fillItem` takes priority.
- `width` / `height` (`real`): explicit default logical size `20 × 20` (an
  `implicitWidth` declaration would be unconditionally overridden by the engine;
  explicit `width`/`height` are not touched). The engine's implicit size equals the
  path bounds (the geometry), so layout uses the explicit size.

The `control` (required on `OctagonShape`) is satisfied by an internal default
instantiation inside this component; replacing it is an advanced use (custom geometry
source). The `settings` object is an internal eight-point contract whose four corner
cuts are always `shortEdge / 2`; modifying it breaks the shape's self-consistency, so
`Crystal` exposes no settings configuration surface.

## Signals

This type defines no additional signals. (It inherits the standard
`OctagonShape`/`Shape`/`Item` signals.)

## Methods

This type defines no additional methods.

## Hit mask

The hit mask is delegated to `QoolBoxShapeControl::contains` (the bounding rectangle
with the four corner-cut domains excluded; the hypotenuse and the eight vertices hit
— open-set semantics, matching the visible shape). Because Qt's hover dispatch only
checks an item's own `contains` (not ancestor masks), a host `MouseArea` must mount
`containmentMask: 组件id.containmentMask` to obtain precise hover.

## Usage Example

Used for a slider handle (square: default logical size `20 × 20`) or track (wide bar:
override `width`/`height` for a wide hexagon). The slider track and handle both use
this component, so their hypotenuse slopes align naturally. Gradient anchors are not
exposed; a host computes them from `(width/2, height/2)` and
`(width - width/2, height/2)`.

```qml
import QtQuick
import Qool

Crystal {
    width: 120
    height: 40
    color: "#4aa3ff"
    borderWidth: 2
}
```
