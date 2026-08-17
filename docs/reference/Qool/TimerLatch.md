# TimerLatch

A timed latch: trigger latches immediately, and a timer releases
automatically — a sliding-window state.

`trigger()` immediately sets `active` to `true` and resets the timer; after
`interval` (default 1000 ms) without another trigger, `active` automatically
falls back to `false`. Repeated triggers within the window reset the timer —
continuous triggering keeps it held (a sliding window). `active` is a
declarative state that can be bound directly (e.g. opacity or expanded
state); `activated` / `deactivated` are the window boundary events.

Any signal source can trigger it (e.g. `Connections { onXxx →
latch.trigger() }`) — a general "just changed" feedback mechanism (the
systematized replacement for the v3 `movementTimer`/`justMoved` pattern:
`Slider` handle-expansion window and scroll-indicator fade delay are both
based on this type).

Unlike an SR latch, release is driven by the timer (not manual reset). Hosts
that only need "execute once after a delay" should use a bare `Timer`.

## Properties

- `interval : int` (default `1000`)
  The hold time in milliseconds. The timer restarts on each trigger.

- `active : bool` (read-only, default `false`)
  Whether the latch is currently held. Set `true` immediately by `trigger()`
  and reset to `false` by the timer after `interval` without another
  trigger.

## Signals

- `activated()`
  Emitted when `active` becomes `true` (on `trigger()`).

- `deactivated()`
  Emitted when `active` becomes `false` (when the timer fires after
  `interval` without another trigger).

## Methods

- `trigger()`
  Latches the state: sets `active` to `true` and restarts the timer. Safe to
  call repeatedly; each call resets the window.

## Usage Example

```qml
import QtQuick
import Qool

TimerLatch {
    id: latch
    interval: 1000
}

// Any signal source drives the latch.
Connections {
    target: someSignalSource
    function onValueChanged() { latch.trigger() }
}

// Bind a declarative state to the latch.
opacity: latch.active ? 1.0 : 0.4
```
