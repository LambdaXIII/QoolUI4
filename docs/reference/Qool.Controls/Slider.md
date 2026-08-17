# Slider

A horizontal slider: a hexagonal gradient track with a crystal diamond
handle (the v3 Color slider visual family, generalized).

`Slider` provides the standard `T.Slider` API (`from`, `to`, `value`,
`stepSize`, `snapMode`, ...). Interaction is the template default (click
jumps, continuous drag, arrow-key stepping — official behavior; the interface
is compatible with `QtQuick.Templates.Slider`). The track and the handle
share the `Crystal` hexagon model (the track is a wide hexagon, the handle a
square diamond — same-model bevel slopes align naturally), the track fills a
`text` → `color` horizontal gradient anchored inside the cut corners (left
end fixed to `Style.text`, right end = `color`, default `Style.accent`), and
the handle's resting color is the gradient sampled at the current value
position (`ColorMapper.colorAt(visualPosition)` — follows the position in
real time).

## Properties

- `color : color` (default `Style.accent`)
  The gradient's right-end color (the left end is fixed to `Style.text`) —
  and the handle's sample source. Changing this one property changes the
  whole track gradient + handle sampling. The track gradient is inline by
  default and cannot be replaced wholesale (v4 shrink: change color via
  `color`, change size via `width`/`height` overrides).

- `valueVelocity : real` (read-only)
  Value-change rate (values per second; `NumberNotifier` 200 ms sampling,
  directed, drops to zero on a sudden stop).

- `justMoved : bool`
  "A value was just written" declarative latch window — 500 ms, sliding
  (continuous changes keep it held). `true` while any value change is within
  the window.

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`.

- `preferredHeight : real` (read-only)
  Resting height of the crystal handle and track (contracted state)
  — `root.height - Qore.bound(3, root.height * 0.25, 25)`. When expanded the
  crystal fills the control's full height. Usable by the host in external
  layout calculations.

Inherited from `T.Slider`: `from`, `to`, `value`, `stepSize`, `snapMode`,
`live`, `pressed`, `position`, `visualPosition`, `increase()`, `decrease()`,
`moved()`, and all other `Slider`/`Control` members. See the Qt
documentation for the inherited members. The default implicit size is
80 × 25.

## Signals

This type defines no additional signals (inherits all signals from
`T.Slider`, notably `moved()`, `valueChanged`, `pressedChanged`).

## Methods

This type defines no additional methods (inherits all methods from
`T.Slider`, notably `increase()` and `decrease()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

Slider {
    width: 300
    from: 0
    to: 100
    value: 50
    onValueChanged: console.log("value:", value)
}

// Custom accent: changes the whole track gradient and handle sampling.
Slider {
    width: 300
    color: Style.active.accent
}

// Inverted range: scale reverses, gradient/sampling follow automatically.
Slider {
    width: 300
    from: 100
    to: 0
    value: 30
}
```

## Interaction feedback

- Hover / press / just-moved (the 500 ms window after a value change): the
  handle expands to the control's full height (resting = `preferredHeight` —
  `Qore.bound(3, height × 0.25, 25)`; the track and handle share the same
  resting height, stay center-aligned, and the handle's bevels hug the
  track's bevels), animated under the `animationEnabled` gate. The hover
  cursor becomes a horizontal double-arrow (only when `enabled`).
- Programmatic `value` writes (e.g. an external binding): the handle expands
  for about 500 ms (`justMoved` — "a value was written gets feedback",
  regardless of who wrote it); continuous changes keep the window from
  dropping via the sample-level `valueVelocity` resets.
- Inverted range (`from > to`): the scale reverses; the gradient and the
  sampling follow `visualPosition` automatically.

The `handle` delegate must self-write its `x`/`y` (the `T.Slider` template
does not inject positioning — official convention; a host replacing `handle`
must do the same). The expanded handle fills the control height (never
exceeds the bounds) — `clip` or not does not affect the feedback (the v3
"diamond pops out of the track" deliberate effect was removed).
