# QoolBoxGadget

The octagon control-point calculator (a gadget): a single eight-point model driven by
`cut` hard parameters plus an expected size. Mounted under a standard `ShapeControl`
(a `ShapeControl` child object is auto-associated with its `control`), it outputs a
single eight-point set `pointTL`…`pointLT` (each point also has `pointTLx`/`pointTLy`
and so on component properties), parameterized by `borderWidth`: `0` is the outer
outline, `> 0` shrinks the 8 points inward along each edge's normal, and `< 0`
expands outward. A dual-instance stroke means a host instantiates two gadgets (the
outer ring with `borderWidth 0`, the inner ring with the target stroke width) — the
component literal only has 8 points.

## Semantics

`cutTL`…`cutBR` are hard parameters: the shape is determined by `cut` and is not
compressed when the size is insufficient. `width`/`height` (read via `control`) are
the expected size — the figure tries to match, and in the extreme case (cut demand
exceeding the expected size) it overflows symmetrically from the expected center
rather than compressing `cut`. A negative `cut` is clamped to `0` (a right-angle
point). All degenerate states (rectangle, diamond, triangle, convex polygon, coincident
points, line segment) are well-defined, legal limit forms.

## Properties

Inputs:

- `cutTL` / `cutTR` / `cutBL` / `cutBR` (`real`): the four corner cut sizes (hard
  parameters, default `0` = right angle).
- `borderWidth` (`real`): the inset distance. Default `0` = outer outline; in a
  dual-instance stroke the inner instance is set to the target stroke width. It never
  participates in `referenceBox` (this instance's sole free input).
- `offsetX` / `offsetY` (`real`): the overall translation (the only position input).
  Default `0`.
- `width` / `height` (`real`): read via `control` (the expected size) — a host sets
  the `target`'s geometry instead of sizing the gadget separately.
- `referenceBox` (`QoolBoxGadget`): the geometry reference source. When another
  gadget is assigned, this gadget's `origin`, `offset`, `vec*`, `used*`, and `cut*`
  are overridden by it (reference priority); only `borderWidth` and the shrink layer
  are handled by this gadget itself — the geometry is fully delegated. Assignment is
  validated: if the target already has a reference (chaining or a ring) or is itself
  (self-reference), the assignment is rejected and this gadget's `referenceBox` is set
  to `null`.

Derived (read-only):

- `usedWidth` / `usedHeight` (`real`): the carried size — `max(expected size,
  diagonal cut sum)`, so the four edge lengths are structurally non-negative with no
  corner interaction.
- `pointTL`…`pointLT` (`point`): the 8 output points, each with `pointTLx`/`pointTLy`
  (and so on) components. Naming convention: the first letter is the edge, the second
  is the endpoint position on that edge — `TL` is the Top edge's Left endpoint, `LT`
  is the Left edge's Top endpoint (the 8 names are unambiguous).

It also inherits `control` and `target` from `ShapeControlGadget`.

## Signals

All properties notify through Qt's auto-generated `xxxChanged` signals, guarded so a
signal is emitted only when the actual value changes. The `referenceBoxChanged`
signal is declared explicitly (from the hand-written setter).

## Methods

- `contains(point)` → `bool`: precise octagon hit test. The hypotenuse, edges, and
  vertices hit (open-set semantics); the cut-corner regions do not hit. `borderWidth`
  does not affect the judgment (either instance of a dual-instance stroke gives the
  same semantics). Under `referenceBox` mode the geometry reference is followed
  automatically.

## Usage Example

`QoolBoxShapeControl` mounts two `QoolBoxGadget` instances internally (the outer
outline and the inner inset ring). A gadget is normally consumed through that control
rather than instantiated directly:

```qml
import QtQuick
import Qool

QoolBox {
    width: 240
    height: 140
}
```
