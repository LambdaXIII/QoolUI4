# RangeSlider

An interval slider built in three layers: a static hexagonal track, a
`RangeHandle` (the range interaction component), and a pluggable `surface`
(by default a single crystal foreground spanning the whole interval).
The selected interval is displayed as one unified shape — left point +
straight middle + right point — instead of two separate handles, with both
points overflowing the interval box outward.

`RangeSlider` keeps the full `T.RangeSlider` API (`first`/`second` values,
`from`, `to`, `setValues()`, keyboard stepping — template behavior). The
three-layer structure decouples behavior from appearance:

- **Layer 1 — value model + static background**: the `T.RangeSlider`
  template and a static `Crystal` hexagonal track (`backgroundColor` at 75%
  opacity, `borderColor` stroke). The track does not participate in
  interaction feedback (the visual focus is on the foreground); it
  overflows the control by its own point height, like the foreground.
- **Layer 2 — `RangeHandle`**: a public standalone component holding the
  three-zone drag interaction (endpoint hit zones + middle travel zone)
  and emitting intent signals with pixel deltas. Replacing the
  `rangeHandle` property with a subclass instance is **behavior
  plugging**.
- **Layer 3 — `surface`**: an `Item` property (accessed via
  `rangeHandle.surface`) whose layout is the surface's own responsibility —
  the `RangeHandle` only sets its parent. The default surface fills the
  interval box and hosts the crystal foreground. Replacing it with any
  `Item` is **appearance plugging**; the two plug points are independent.

Geometry: the `rangeHandle`'s x/y/width/height **is** the interval box —
the value→position mapping is a single `availableWidth × position` formula
(the handle never copies template travel semantics). Endpoint dragging is
clamped in the value domain (each endpoint cannot cross the other),
middle-zone dragging shifts the interval as a whole (width unchanged,
clamped at the range boundary). Clicks do nothing; keyboard behavior is
the template's.

## Properties

- `color : color` (default `Style.accent`)
  The foreground fill color (the crystal spanning the interval).
- `backgroundColor : color` (default `Style.buttonText`)
  The track background color (rendered at 75% opacity by the default
  track).
- `borderColor : color` (default `ThemeHQ.recommendForeground(backgroundColor)`)
  The stroke color of the foreground crystal and the track.
- `firstJustMoved : bool` / `secondJustMoved : bool`
  "A value was just written" declarative latch windows — 500 ms each,
  sliding (continuous changes keep them held) and **independent** per
  endpoint: writing one endpoint latches only its own window. Together
  with the handle's `down`/`hovered` they drive the foreground expansion.
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`.
- `rangeHandle : RangeHandle`
  The range interaction component (default: an internal instance).
  Replacing it with a subclass instance overrides behavior — **behavior
  plugging**. The interval-box bindings (x/y/width/height) and the
  delta→value conversion (`wannaMoveFirstX`/`wannaMoveSecondX`/
  `wannaMoveRangeX`) are applied dynamically — a replaced instance is
  controlled the same way.

Inherited from `T.RangeSlider`: `first`, `second` (each a `RangeSliderHandle`
with `value`/`position`/`visualPosition`/`pressed`), `from`, `to`,
`stepSize`, `snapMode`, `live`, and all other `RangeSlider`/`Control`
members. See the Qt documentation for the inherited members. The default
implicit size is 80 × 25.

## Signals

This type defines no additional signals (inherits all signals from
`T.RangeSlider`, notably `first.moved()` and `second.moved()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.RangeSlider`, notably `setValues()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

RangeSlider {
    width: 300
    from: 0
    to: 100
    // Official contract: set both values at once via setValues()
    // (first.value/second.value have a circular dependency; assigning
    // them separately before completion may clamp each other).
    Component.onCompleted: setValues(25, 75)
}

// Custom colors: interval fill, track background, and stroke.
RangeSlider {
    width: 300
    color: Style.active.accent
    backgroundColor: Style.active.background
    borderColor: Style.active.text
}

// Appearance plug: replace the surface with any Item — the surface lays
// itself out (e.g. anchors.fill: parent) to fill the interval box.
RangeSlider {
    width: 300
    rangeHandle: RangeHandle {
        surface: Rectangle {
            anchors.fill: parent
            radius: 3
            color: Style.active.accent
        }
    }
}

// Behavior plug: subclass RangeHandle, then replace the property.
// The interval-box bindings and the signal conversion apply to the
// replacement instance as well.
RangeSlider {
    width: 300
    rangeHandle: LoggingHandle {}
}
```

## Interaction feedback

- Three-zone drag: the left zone (at the interval's left endpoint, width
  `min(width/2, height/2) + extension`) drags `first`, the right zone drags
  `second`, the middle zone (the travel, `width - height`) drags the whole
  interval. The payloads are pixel deltas; the conversion and clamping are
  in the value domain:
  - dragging `first`: `first` ∈ `[from, second.value]` (can coincide, never
    crosses `second`);
  - dragging `second`: `second` ∈ `[first.value, to]`;
  - dragging the middle: both endpoints shift together, the interval width
    stays constant, and the shift stops at the range boundary as a whole
    (clamped to `[from - first.value, to - second.value]`).
- Clicks do nothing — the interaction is drag-only; keyboard stepping
  remains the template's behavior.
- Expansion feedback: while a value was just written (either independent
  latch), or while a zone is pressed/hovered, the foreground crystal fills
  the interval box (straight middle = the interval, points overflowing
  `height/2`); at rest it contracts by `crystalShrinkSize`
  (`Qore.bound(3, height * 0.25, 25)`) — the straight middle becomes
  `interval width - shrink`, the points overflow `(height - shrink)/2`.
  Programmatic value writes expand the foreground via the latches even
  when the control is disabled (data feedback does not follow interaction
  disablement).
- Inverted range (`from > to`): positions reverse; the interval stays
  positive (the template guarantees `first.position <= second.position`).
- Narrow/coincident intervals: the crystal's cut follows the shape's own
  geometry (`min(width, height)/2`), so a zero-width interval (coincident
  endpoints) degrades to a crystal (diamond) — no special casing.
