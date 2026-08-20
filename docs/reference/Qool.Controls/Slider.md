# Slider

A slider (horizontal/vertical + RTL): a hexagonal gradient track with a
crystal diamond handle (the v3 Color slider visual family, generalized).

`Slider` provides the standard `T.Slider` API (`from`, `to`, `value`,
`stepSize`, `snapMode`, `orientation`, ...). Interaction is the template
default (click jumps, continuous drag, arrow-key stepping — official
behavior; the interface is compatible with `QtQuick.Templates.Slider`). The
track and the handle share the `Crystal` hexagon model (the track is a wide
hexagon, the handle a square diamond — same-model bevel slopes align
naturally), the track fills a `Style.buttonText` (75% opacity) → `Style.accent`
gradient anchored to the value-increasing side (see "Orientation and RTL"
below; the `from` end = `Style.buttonText` at 75% opacity — the name follows
the Qt palette convention, the semantics is the control foreground color —
the `to` end = `Style.accent`), and the handle's resting color is the
gradient sampled at the current value position, rendered opaque
(`ColorMapper.colorAt(position)` — follows the position in real time;
`position` is not mirrored, matching the gradient geometry).

- **Track** — a static `Crystal` hexagonal gradient track in the
  `background`, full-width, held at the rest height and vertically centered.
  It does not participate in interaction feedback.
- **Handle** — the default `handle` hosts the crystal diamond (the visual
  focus), which expands to the handle's full size while hovered, pressed, or
  while a recent value change holds (via `ItemAnimatedResizer` + a
  `TimerLatch`), and contracts to `size − shrinkSize` when none holds. The
  handle carries a hover cursor (`Qt.SizeHorCursor` horizontal /
  `Qt.SizeVerCursor` vertical, gated by `enabled`).
  Replacing `handle` with any `Item` is behavior plugging (template handle
  contract) — the positioning binding is the host's responsibility (the
  template never moves handles).

## Orientation and RTL

`orientation` (`Qt.Horizontal`/`Qt.Vertical`) and RTL (`LayoutMirroring`)
are orthogonal:

- **Axis** — `horizontal` picks the handle's travel axis; the track
  contracts and centers along the axis' normal. The handle's edge length is
  the normal size (`side = horizontal ? availableHeight : availableWidth`),
  so the diamond stays square in both orientations.
- **RTL affects only horizontal** — the handle travels via `visualPosition`
  (mirrored: value-increasing moves left) and the gradient's `x` endpoints
  swap so the accent stays on the value-increasing side.
- **Vertical ignores RTL** — Qt's vertical slider always shows value
  increasing upward (`visualPosition` is constantly `1 − position`, so a
  `LayoutMirroring` has no effect); the gradient runs bottom (`from`) →
  top (`to`).
- **Implicit size** swaps with orientation (`150 × 25` ↔ `25 × 150`),
  matching the official "vertical is narrow" convention.
- **Value mapping** is the template default — drag/keys/wheel map x or y per
  orientation, RTL reverses via `visualPosition`. No self-written logic.

## Properties

This control defines **no per-instance color properties** — colors come from
the unified style interface (`Style`). The host recolors via attached-property
propagation: set `Style.accent` / `Style.buttonText` on this control or any
ancestor (propagation granularity covers a single instance up to the whole
tree).

**Color model** — a contrast pair, control foreground → accent:
- Track gradient `from` end = `Style.buttonText` at 75% opacity (the name
  follows the Qt palette convention; the semantics is the **control
  foreground color**), `to` end = `Style.accent` — control foreground →
  accent, contrasting by design. The `to` end sits on the value-increasing
  side (horizontal LTR right, RTL left; vertical top).
- Track stroke = `ThemeHQ.recommendForeground(Style.buttonText)` — the
  contrast-recommended foreground derived automatically (contrast-safe
  without host intervention). The handle stays un-stroked (the diamond's
  small size makes a stroke visually heavy).
- The handle's resting color samples the gradient at the current value
  position, rendered opaque (not the track's 75% transparency).

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates
  the handle expansion animation (`ItemAnimatedResizer`) and the
  focus-highlight border transition; when off, both switch instantly
  instead of animating.

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
// Colors are Style attached properties — set on this instance to recolor
// just this slider, or on an ancestor to cover a subtree.
Slider {
    width: 300
    Style.accent: Style.active.accent
}

// Inverted range: scale reverses, gradient/sampling follow automatically.
Slider {
    width: 300
    from: 100
    to: 0
    value: 30
}

// Vertical: implicit size swaps to 25×150, handle travels along y
// (value increases upward), gradient runs bottom → top.
Slider {
    orientation: Qt.Vertical
    value: 0.6
}
```

## Interaction feedback

- Hover / press / just-moved (the 500 ms sliding `TimerLatch` window after a
  value change, hosted inside the handle): the handle expands to the
  handle's full size (resting size is `side − Qore.bound(3, side × 0.25,
  25)` where `side` is the track's normal size — an internal
  default-implementation
  convention shared by the default handle and the default track; the track
  and handle share the same resting height, stay center-aligned, and the
  handle's bevels hug the track's bevels), animated under the
  `animationEnabled` gate via `ItemAnimatedResizer`. The hover cursor becomes
  a horizontal double-arrow (vertical: a vertical double-arrow) only when
  `enabled`. When `enabled` is off the
  handle freezes (the resizer's `enabled` follows `root.enabled`) — no hover,
  no expansion, no cursor feedback.
- Programmatic `value` writes (e.g. an external binding): the handle expands
  for about 500 ms (the same latch — "a value was written gets feedback",
  regardless of who wrote it). The latch is internal to the handle (there is
  no public "just moved" property; the feedback is observed through the
  handle itself).
- Inverted range (`from > to`): the scale reverses; the gradient and the
  sampling follow `position` automatically.
- Keyboard focus highlight: while the slider holds keyboard focus
  (`visualFocus` — Qt's standard semantic, `true` only when focus was
  acquired through keyboard navigation, i.e. Tab/Backtab/shortcut; mouse,
  programmatic and window-switch focus do not light it), the default track
  border switches to `Style.highlight` and reverts to
  `ThemeHQ.recommendForeground(Style.buttonText)` on losing focus, animated
  under the `animationEnabled` gate. The highlight
  color is fixed (`Style.highlight`, no public property) and lives inside
  the default `background` only — replacing `background` removes it.
  Focusability stays at the Qt default — the control does not set
  `activeFocusOnTab`; the mechanism is ready to use once the host enables
  focus the Qt-standard way (`activeFocusOnTab` or `forceActiveFocus`).

The `handle` delegate must self-write its `x`/`y` (the `T.Slider` template
does not inject positioning — official convention; a host replacing `handle`
must do the same). The expanded handle fills the control height (never
exceeds the bounds) — `clip` or not does not affect the feedback (the v3
"diamond pops out of the track" deliberate effect was removed).
