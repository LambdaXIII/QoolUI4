# VerticalSlider

A vertical slider: a hexagonal gradient track with a crystal diamond handle
(the verticalized `Slider`).

`VerticalSlider` shares its origin with `Slider` (crystal hexagon model,
gradient sampling, expansion feedback, latch mechanism) with the layout axes
swapped: the track is a slim hexagon (top/bottom points + left/right
straight edges), the handle travels vertically, and **the bottom is `from`**
(value increases upward). Interaction is verticalized (a full-area
`MouseArea` maps vertically — click jumps + continuous drag; the `T.Slider`
mouse mapping is horizontal and would misalign under a vertical layout, so
the template press is intercepted and replaced), and the keyboard Up/Down
step the value (the template's Left/Right handling is kept by the base).

## Properties

- `color : color` (default `Style.accent`)
  The gradient's top color (the bottom end is fixed to `Style.text`) — and
  the handle's sample source. Changing this one property changes the whole
  track gradient + handle sampling. The track gradient is inline by default
  and cannot be replaced wholesale (v4 shrink: change color via `color`,
  change size via `width`/`height` overrides).

- `valueVelocity : real` (read-only)
  Value-change rate (values per second; `NumberNotifier` 200 ms sampling,
  directed, drops to zero on a sudden stop).

- `justMoved : bool`
  "A value was just written" declarative latch window — 500 ms, sliding
  (continuous changes keep it held).

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain, falling back to
  `Style.animationEnabled`.

- `preferredWidth : real` (read-only)
  Resting width of the crystal handle and track (contracted state)
  — `root.width - Qore.bound(3, root.width * 0.25, 25)`. When expanded the
  crystal fills the control's full width. Corresponds to `Slider`'s
  `preferredHeight` (axis swap). Usable by the host in external layout
  calculations.

Inherited from `T.Slider`: `from`, `to`, `value`, `stepSize`, `snapMode`,
`live`, `position`, `visualPosition`, `increase()`, `decrease()`, `moved()`,
and all other `Slider`/`Control` members. See the Qt documentation for the
inherited members. The default implicit size is 25 × 80 (exchanged from
`Slider`'s 80 × 25).

## Signals

This type defines no additional signals (inherits all signals from
`T.Slider`).

## Methods

This type defines no additional methods (inherits all methods from
`T.Slider`, notably `increase()` and `decrease()`, which the keyboard
Up/Down keys call).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

VerticalSlider {
    height: 300
    from: 0
    to: 100
    value: 60
    onValueChanged: console.log("volume:", value)
}

// Inverted range: positions reverse; gradient/sampling follow automatically.
VerticalSlider {
    height: 300
    from: 100
    to: 0
    value: 40
}
```

## Interaction feedback

- Hover / press / just-moved (the 500 ms window after a value change): the
  handle expands to the control's full width (resting = `preferredWidth` —
  `Qore.bound(3, width × 0.25, 25)`; the track and handle share the same
  resting width, stay center-aligned, and the handle's bevels hug the
  track's bevels), animated under the `animationEnabled` gate. The hover
  cursor becomes a vertical double-arrow (only when `enabled`).
- Programmatic `value` writes (e.g. an external binding): the handle expands
  for about 500 ms (`justMoved`); continuous changes keep the window from
  dropping via the sample-level `valueVelocity` resets.
- Inverted range (`from > to`): positions reverse; the gradient and the
  sampling follow `position` automatically.

The `handle` delegate must self-write its `x`/`y` (the vertical travel
formula: horizontal centering, `y` travels top-to-bottom where `position 0`
sits at the bottom). The expanded handle fills the control width (never
exceeds the bounds) — `clip` or not does not affect the feedback.
