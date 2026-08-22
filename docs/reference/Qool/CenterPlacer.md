# CenterPlacer

A center-coordinate placement widget — a `SmartObject` (non-`Item`
container, no rendering) that synchronizes `centerx`/`centery` with an
arbitrary target object's `x`/`y` in both directions.

`CenterPlacer` is a pure geometry capability: mount it on any object that
carries `x`/`y`/`width`/`height` (an `Item`, or a `QtObject` with those
properties defined), then read or write `centerx`/`centery` and the
coordinates are equivalent to reading or writing the target's top-left
`x`/`y` (center semantics vs top-left semantics: `center = x + width / 2`).
This is the coordinate capability behind surface cursors (a cursor placed
by its center at a value position) and is independent of visuals.

Two coordinate systems are fully usable: consumers position by top-left
(`x`/`y`) or by center (`centerx`/`centery`) and may switch freely — both
stay in sync.

## Coordinate system

- `centerx` is the target's center point on the X axis
  (`target.x + target.width / 2`); `centery` the same on Y.
- Writing `centerx` assigns `target.x = centerx - target.width / 2`
  (the target's size participates), and vice versa.
- Size changes on the target update the center (the center reflects the
  true position as the root resizes).
- Synchronization is programmatic via `Connections` — no bindings, no
  binding loops. Same-value guards break both write-back directions.

## Properties


  The target is an open interface: it may be re-assigned at any time
  (e.g. reusing the placer for another surface/cursor). On switch the
  placer immediately re-reads the new target's position into
  `centerx`/`centery` (the target is the single source of truth — the
  old center value does not linger) and the internal connections move
  to the new target; assigning `null` is safe (the center holds its
  current value, nothing is written).

- `centerx : real`
  The target's center X. Reading reflects `target.x + width/2`; writing
  assigns `target.x = centerx - width/2`.

- `centery : real`
  The target's center Y. Reading reflects `target.y + height/2`; writing
  assigns `target.y = centery - height/2`.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

Item {
    id: cursor
    width: 40
    height: 40
}

// Place the cursor by its center point; x/y follow automatically.
CenterPlacer {
    target: cursor
    centerx: 120
    centery: 80
}

// Reading center coordinates reflects the target's actual position.
CenterPlacer {
    id: placer
    target: cursor
}

// cursor.x == 100 after the target's width is set — the center stays put.
```

### Note on binding use

If a consumer drives `centerx`/`centery` with a QML binding, the placer's
internal `onXChanged` write-back (`centerx = x + width/2`) overwrites that
binding with an explicit assignment (QML explicit assignment breaks the
binding). Prefer event-driven assignment of the center coordinates, or
guarantee the target's `x`/`y` are driven only through the center (the
same-value guards make the loop safe).
