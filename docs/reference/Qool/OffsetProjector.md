# OffsetProjector

A displacement-mapping node that converts between a displacement direction and a
distance-measurement direction. It takes a displacement direction (`direction`), a
distance-measurement direction (`refDirection`), and a movement distance along that
measurement direction (`refDistance`), and outputs the actual displacement vector
`offset`, satisfying `offset ∥ direction_unit` and
`offset·refDirection_unit == refDistance`:

```
offset = direction_unit * refDistance / (direction_unit · refDirection_unit)
```

The typical use is an inset stroke on a convex polygon: the inner point equals the
outer point plus `offset` (the stroke width is measured along the edge normal, and
`refDistance` binds the stroke width directly — a zero-coefficient hookup);
subtraction produces reverse movement (expansion). The `direction`/`refDirection`
pair data is provided by the shape's features; the node itself is shape-agnostic.

## Default-value self-consistency

When used standalone (no properties set), `refDistance` is `0` and `offset` is always
the zero vector.

## Degenerate contract

- Any input vector being the zero vector → `offset` is the zero vector.
- `refDistance == 0` → `offset` is the zero vector.
- The two directions being orthogonal (dot product ≈ 0) → `offset` is the zero vector
  (with float-noise tolerance).

## Notification semantics

If an input changes but the actual result does not, no `offsetChanged` is emitted
(output value equality guard) — for example, when `refDistance == 0`, changing the
direction does not propagate downstream; restoring a non-zero value automatically
recovers the chain.

## Sign rule (debugging guide)

The dot product of `direction` and `refDirection` must be greater than `0` (same side,
pointing inward); the node does not validate it. The observable symptom of a
mismatched pair (dot product `≤ 0`) is an inverted `offset` — the stroke expands
outward beyond the geometry. A near-orthogonal pair (misconfiguration) yields a zero
`offset`.

## Properties

- `direction` (`vector2d`): the displacement direction (the desired movement
  direction). Default `(1, 0)`. It is normalized during computation.
- `refDirection` (`vector2d`): the direction along which distance is measured.
  Default `(1, 0)`. It is normalized during computation; its dot product with
  `direction` must be `> 0`.
- `refDistance` (`real`): the movement distance along `refDirection`. Default `0`.
  When `0`, `offset` is always the zero vector (direction input changes do not
  produce `offsetChanged` notifications).
- `offset` (`vector2d`, read-only): the actual displacement vector. It satisfies
  `offset ∥ direction_unit` and `offset·refDirection_unit == refDistance`.

## Signals

This type defines no additional signals beyond the auto-generated ones, most notably
`offsetChanged` (guarded by output value equality).

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

OffsetProjector {
    id: inset
    direction: Qt.vector2d(1, 1)        // move along the hypotenuse normal
    refDirection: Qt.vector2d(0, 1)     // stroke width measured vertically
    refDistance: borderWidth            // binds the stroke width directly
}
```
