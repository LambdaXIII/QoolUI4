# RangeSlider

An interval slider built on the `T.RangeSlider` template: a static
hexagonal track, template `first`/`second` handles (transparent by
default, activating the template interaction), and a pluggable `surface`
(by default a single crystal foreground spanning the whole interval).
The selected interval is displayed as one unified shape — left point +
straight middle + right point — instead of two separate handles, with both
points overflowing the interval box outward.

`RangeSlider` keeps the full `T.RangeSlider` API (`first`/`second` values,
`from`, `to`, `stepSize`, `snapMode`, `live`, `setValues()`). Setting the
default transparent `first.handle`/`second.handle` activates the template
interaction state machine, so **snap, live, keyboard stepping, nearest
click behavior and endpoint clamping are all template behavior** — nothing
is re-implemented. The `surface` is the only appearance layer:

- **Track** — a static `Crystal` hexagonal track (`backgroundColor` at 75%
  opacity, `borderColor` stroke). It does not participate in interaction
  feedback (the visual focus is on the foreground); it overflows the
  control by its own point height, like the foreground.
- **Handles** — `first.handle`/`second.handle` default to transparent
  squares (`width = height = availableHeight`) centered on the value
  position (`x = leftPadding + availableWidth × position − width/2`),
  i.e. the handle center **is** the interval-box endpoint. Replacing them
  with any `Item` is **behavior plugging** (template handle contract):
  custom hit area, visuals and cursor. The positioning binding is the
  host's responsibility — the template never moves handles.
- **`surface`** — an `Item` property of `RangeSlider` itself. The
  component imposes the interval-box geometry (x/y/width/height = the
  value→position mapping) via dynamic bindings, so a replaced surface
  that fills itself yields the exact interval without the host computing
  the mapping. The default surface hosts the crystal foreground.
  Replacing it with any `Item` is **appearance plugging**; the two plug
  points are independent.

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
  with the handles' `pressed`/`hovered` they drive the foreground
  expansion.
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`.
- `surface : Item`
  The interval foreground (default: an internal `Item` hosting the
  crystal). The interval-box geometry (x/y/width/height) is imposed by
  dynamic bindings — a replaced instance is controlled the same way;
  filling it yields the exact interval. **Appearance plugging**.

Inherited from `T.RangeSlider`: `first`, `second` (each a
`RangeSliderHandle` with `value`/`position`/`visualPosition`/`pressed`/
`hovered`), `from`, `to`, `stepSize`, `snapMode`, `live`, and all other
`RangeSlider`/`Control` members (including `first.handle`/`second.handle`,
the template handle plug points). See the Qt documentation for the
inherited members. The default implicit size is 80 × 25.

## Signals

This type defines no additional signals (inherits all signals from
`T.RangeSlider`, notably `first.moved()` and `second.moved()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.RangeSlider`, notably `setValues()`, and the handles'
`increase()`/`decrease()` keyboard stepping).

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

// Appearance plug: replace the surface with any Item — the component
// imposes the interval-box geometry, so filling it (e.g. anchors.fill:
// parent) yields the exact interval.
RangeSlider {
    width: 300
    surface: Rectangle {
        anchors.fill: parent
        radius: 3
        color: Style.active.accent
    }
}

// Behavior plug: replace the template handles. Positioning is the host's
// responsibility (the template never moves handles) — the center-aligned
// formula keeps the handle centered on the interval endpoint.
RangeSlider {
    width: 300
    first.handle: Rectangle {
        width: height
        height: parent.availableHeight
        radius: height / 2
        color: Qt.alpha(parent.color, 0.55)
        x: parent.leftPadding
            + parent.availableWidth * parent.first.position - width / 2
        y: parent.topPadding
    }
}
```

## Interaction feedback

- **Dragging** is template behavior: each handle is hit-tested by the
  template (press on the handle, drag; press on the track selects the
  nearest endpoint via the template's `nearest` logic). `snapMode`/
  `stepSize`/`live` are honored exactly as in `T.RangeSlider` — snapping
  during drag (SnapAlways) or on release (SnapOnRelease), `live: false`
  keeping `value` unchanged while the visual position follows and
  settling on release. There is no overall-interval dragging (the
  template only moves single endpoints); hosts needing it can build it
  (a `MouseArea` in the content that operates both endpoints at once —
  endpoint clamping and snapping remain the template's).
- Keyboard stepping (`increase()`/`decrease()`, direction keys after
  focus) steps by `stepSize` with template clamping.
- Expansion feedback: while a value was just written (either independent
  latch), or while an endpoint is pressed/hovered, the foreground crystal
  fills the interval box (straight middle = the interval, points
  overflowing `height/2`); at rest it contracts by `crystalShrinkSize`
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
