# NumberNotifier

A numeric property observer: continuously samples a single numeric property
via a pull-based timer loop and reports its change velocity. It measures
*current rate of change* ("tachometer" semantics), not a change event — if
the property stops moving, the next sample sees a zero difference and the
velocity naturally falls to zero.

Unlike an event-driven watcher, it does **not** connect to the property's
notify signal. Every `interval` milliseconds (default 200) it actively
`read()`s the property value and computes the difference from the previous
sample:

- `velocity = diff / (interval / 1000)` — value-per-second, **directional**
  (positive on increase, negative on decrease).
- A non-zero difference (a change detected at sample granularity) emits
  `valueUpdated(newValue, oldValue)`.

`valueUpdated` carries the two **adjacent sample snapshots**, not the
true-change instants: delivery is delayed by at most `interval`, and
round-trip changes between samples may be missed. This distinguishes it from
the property's own `Changed` notification (which is exact); a host needing
precise change notifications should listen to the original property
directly.

## Dual usage modes

Both modes feed the same sampling loop:

- **`NumberNotifier on value` syntax** — QML attaches the notifier to a
  property; the engine calls `setTarget()` when the property assignment
  fails, giving a reference to the observed property. Observation is
  read-only; this type never writes a value.
- **Plain object usage** — set `target` + `property`; changing either
  rebuilds the observation.

The two modes are mutually exclusive; when both `target` and `property` are
set, that (explicit) path takes precedence.

## Specialization and bounds

Specialized for `real`: `read().toReal()` (int-compatible). Boundary cases —
`target` null, invalid property, or a non-finite read value — reset the
baseline and zero `velocity` silently (no error reported; the zeroed
velocity is itself the signal).

## Properties

- `target : object` (read/write)
  The object whose property is observed. Setting it rebuilds the
  observation.

- `property : string` (read/write)
  The name of the numeric property to observe on `target`. Setting it
  rebuilds the observation.

- `interval : int` (default `200`)
  Sampling period in milliseconds. Values `<= 0` are clamped to `1` (Qt
  treats `0` as "as fast as possible").

- `velocity : real` (read-only)
  Current rate of change in value-per-second, directional (positive
  increase, negative decrease). Falls to `0` when the observed property
  stops changing or the observation is invalid.

## Signals

- `valueUpdated(newValue : real, oldValue : real)`
  Emitted when a sample detects a change (non-zero difference). Carries the
  two adjacent sample snapshots, not the true-change instants (see above).

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

// Attach via the `on` syntax: sample `someObject.value` every 100ms.
NumberNotifier on someObject.value {
    interval: 100
    onValueUpdated: (newValue, oldValue) => {
        // react to a detected change (snapshot pair)
    }
}

// Or plain object usage with explicit target + property.
NumberNotifier {
    target: someObject
    property: "value"
    interval: 100
    onValueUpdated: (newValue, oldValue) => {
        // newValue is the current value; oldValue the previous sample
    }
}
```
