# GeoLocker

A geometry locker — a `SmartObject` (non-`Item` container, no rendering)
that locks `target`'s `x`/`y`/`width`/`height` to `lockTo`, with a master
switch and one switch per dimension.

`GeoLocker` is a convenience tool for aligning an overlay/decor layer to a
target item: declare `target` (the manipulated object) and `lockTo` (the
target), and the four built-in bindings keep `target`'s geometry in lockstep
with `lockTo`'s. Each dimension can be released independently. `target` and
`lockTo` accept **any object carrying the four properties**
`x`/`y`/`width`/`height` — an `Item`, or a `QtObject` with those
properties defined.

### Coordinate system

**`x`/`y` are `lockTo`'s coordinates in *its parent's* coordinate system.**
When `target` and `lockTo` share a parent this is the intuitive
alignment semantics. When they have different parents, the locked value is
`lockTo`'s parent-space coordinate — *not* a position relative to
`target`'s parent — so cross-parent alignment requires the host to convert
(`mapToItem`) before assigning `target`'s coordinates.

### Switch semantics

A dimension switch off (or the master `enabled` off) releases that lock:
the binding becomes inactive, `target` keeps its last value and is free.
Re-enabling resumes the lock (following `lockTo`'s current value / next
change).

## Properties

- `enabled : bool` (default `true`)
  Master switch — off releases all four locks.

- `xEnabled : bool` (default `true`)
  Lock `target.x` to `lockTo.x`.

- `yEnabled : bool` (default `true`)
  Lock `target.y` to `lockTo.y`.

- `widthEnabled : bool` (default `true`)
  Lock `target.width` to `lockTo.width`.

- `heightEnabled : bool` (default `true`)
  Lock `target.height` to `lockTo.height`.

- `target : QtObject`
  The manipulated object (any object with `x`/`y`/`width`/`height` — an
  `Item` or a `QtObject` with those properties).

- `lockTo : QtObject`
  The lock target (any object with `x`/`y`/`width`/`height`).

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

Item {
    id: anchorItem
    width: 120
    height: 40
    x: 30
    y: 20
}

// Same-parent alignment: the overlay tracks anchorItem exactly.
GeoLocker {
    target: overlay
    lockTo: anchorItem
}

Item {
    id: overlay
    color: "transparent"
}

// Per-dimension release: keep size locked, free position.
GeoLocker {
    target: overlay2
    lockTo: anchorItem
    xEnabled: false
    yEnabled: false
}
```
