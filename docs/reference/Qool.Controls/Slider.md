# Slider

A horizontal slider: a hexagonal gradient track with a crystal diamond
handle (the v3 Color slider visual family, generalized).

`Slider` provides the standard `T.Slider` API (`from`, `to`, `value`,
`stepSize`, `snapMode`, ...). Interaction is the template default (click
jumps, continuous drag, arrow-key stepping — official behavior; the interface
is compatible with `QtQuick.Templates.Slider`). The track and the handle
share the `Crystal` hexagon model (the track is a wide hexagon, the handle a
square diamond — same-model bevel slopes align naturally), the track fills a
`backgroundColor` (75% opacity) → `color` horizontal gradient anchored inside
the cut corners (left end = `backgroundColor` at 75% opacity, right end =
`color`, default `Style.accent`), and the handle's resting color is the
gradient sampled at the current value position, rendered opaque
(`ColorMapper.colorAt(visualPosition)` — follows the position in real time).

- **Track** — a static `Crystal` hexagonal gradient track in the
  `background`, full-width, held at the rest height and vertically centered.
  It does not participate in interaction feedback.
- **Handle** — the default `handle` hosts the crystal diamond (the visual
  focus), which expands to the handle's full size while hovered, pressed, or
  while a recent value change holds (via `ItemAnimatedResizer` + a
  `TimerLatch`), and contracts to `size − shrinkSize` when none holds. The
  handle carries a hover cursor (`Qt.SizeHorCursor`, gated by `enabled`).
  Replacing `handle` with any `Item` is behavior plugging (template handle
  contract) — the positioning binding is the host's responsibility (the
  template never moves handles).

## Properties

- `color : color` (default `Style.accent`)
  The gradient's right-end color (the left end is `backgroundColor` at 75%
  opacity) — and the handle's (opaque) sample source. Changing this one
  property changes the whole track gradient + handle sampling. The track
  gradient is inline by default and cannot be replaced wholesale (change
  color via `color`; the background size follows the control automatically).
- `backgroundColor : color` (default `Style.buttonText`)
  The track background color — the gradient's left end, rendered at 75%
  opacity on the track (the handle samples the opaque version).
- `borderColor : color` (default `ThemeHQ.recommendForeground(backgroundColor)`)
  The stroke color of the track. The handle stays un-stroked (the diamond's
  small size makes a stroke visually heavy).
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates
  the handle expansion animation (`ItemAnimatedResizer`); when off, the
  resize jumps instead of animating.

Inherited from `T.Slider`: `from`, `to`, `value`, `stepSize`, `snapMode`,
`live`, `pressed`, `position`, `visualPosition`, `increase()`, `decrease()`,
`moved()`, and all other `Slider`/`Control` members. See the Qt
documentation for the inherited members. The default implicit size is
`150 × 25`, derived from the `background`'s explicit implicit size via the
standard template formula (`leftInset + implicitBackgroundWidth +
rightInset` — the slider has no `contentItem` content of its own).

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

- Hover / press / just-moved (the 500 ms sliding `TimerLatch` window after a
  value change, hosted inside the handle): the handle expands to the
  handle's full size (resting size is `availableHeight −
  Qore.bound(3, height × 0.25, 25)` — an internal default-implementation
  convention shared by the default handle and the default track; the track
  and handle share the same resting height, stay center-aligned, and the
  handle's bevels hug the track's bevels), animated under the
  `animationEnabled` gate via `ItemAnimatedResizer`. The hover cursor becomes
  a horizontal double-arrow (only when `enabled`). When `enabled` is off the
  handle freezes (the resizer's `enabled` follows `root.enabled`) — no hover,
  no expansion, no cursor feedback.
- Programmatic `value` writes (e.g. an external binding): the handle expands
  for about 500 ms (the same latch — "a value was written gets feedback",
  regardless of who wrote it). The latch is internal to the handle (there is
  no public "just moved" property; the feedback is observed through the
  handle itself).
- Inverted range (`from > to`): the scale reverses; the gradient and the
  sampling follow `visualPosition` automatically.

The `handle` delegate must self-write its `x`/`y` (the `T.Slider` template
does not inject positioning — official convention; a host replacing `handle`
must do the same). The expanded handle fills the control height (never
exceeds the bounds) — `clip` or not does not affect the feedback (the v3
"diamond pops out of the track" deliberate effect was removed).
