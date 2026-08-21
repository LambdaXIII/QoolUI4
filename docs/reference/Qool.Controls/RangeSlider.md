# RangeSlider

An interval slider (horizontal/vertical + RTL) built on the
`T.RangeSlider` template: template `first`/`second` handles (transparent
narrow strips by default, activating the template interaction state
machine), a static `Crystal` track, and a foreground crystal hosted in a
`rangeBox` inside the `contentItem` that follows the interval geometry and
expands on hover. The selected interval is displayed as one unified shape
— left point + straight middle + right point.

`RangeSlider` keeps the full `T.RangeSlider` API (`first`/`second` values,
`from`, `to`, `stepSize`, `snapMode`, `live`, `setValues()`). The default
handles activate the template interaction, so **snap, live, keyboard
stepping, nearest click behavior and endpoint clamping are all template
behavior** — nothing is re-implemented.

- **Track** — a static `Crystal` hexagonal track (`Style.buttonText` at 75%
  opacity, `ThemeHQ.recommendForeground(Style.buttonText)` stroke) in the
  `background`, contracted by `shrinkSize` on **both** axes and centered
  (`x = y = shrinkSize / 2`; resting size = container − `shrinkSize` in
  width and height — the shrunk handles stay aligned with the track). It
  does not participate in interaction feedback (the visual focus is on the
  foreground).
- **Handles** — `first.handle`/`second.handle` default to transparent
  narrow strips that **re-orient** with the axis: horizontal is a vertical
  strip (`width = side / 2`, `height = side`), vertical is a horizontal
  strip (`width = side`, `height = side / 2` — full normal, main-thickness
  = normal / 2), where `side = horizontal ? availableHeight : availableWidth`.
  Each carries a hover cursor (`Qt.SplitHCursor` horizontal /
  `Qt.SplitVCursor` vertical, gated by `enabled`). Their positioning uses a
  per-axis non-overlapping formula: horizontal travel `availableWidth −
  width × 2` (both handles' widths deducted), `first` starts at `0`,
  `second` at `width`; vertical travel `availableHeight − height × 2`,
  `first` at `0`, `second` at `height` — so the two never intersect at any
  value. Positioning uses `visualPosition` (RTL/vertical-aware). Replacing
  them with any `Item` is **behavior plugging** (template handle contract)
  — the positioning binding is the host's responsibility, the template
  never moves handles.
- **Foreground** — a `Crystal` hosted in `rangeBox` (an `Item` inside the
  `contentItem`). `rangeBox` maps the interval along the main axis with a
  unified formula: start = `min(first.visualPosition,
  second.visualPosition)` × travel, span = `|second.visualPosition −
  first.visualPosition|` × travel + the point-overflow allowance (the
  allowanced is the shape's own `height` horizontally, `width` vertically —
  cut = short side / 2). The absolute difference keeps the span positive in
  RTL and vertical (where `visualPosition` reverses); under horizontal LTR
  it equals the plain interval, matching the simpler reading. The
  foreground expands to the `rangeBox` size while hovered **or while a
  recent value change holds** (via `ItemAnimatedResizer` + a `TimerLatch`)
  and contracts to `size − shrinkSize` when neither holds.

## Orientation and RTL

`orientation` (`Qt.Horizontal`/`Qt.Vertical`) and RTL (`LayoutMirroring`)
are orthogonal:

- **Axis** — `horizontal` picks the handles' travel axis and the normal
  (`side = horizontal ? availableHeight : availableWidth`) drives the
  track/fill contraction, the shrink amount and the strip orientation.
  The track contracts on both axes (resting size = container −
  `shrinkSize` in width and height) and stays centered.
  `shrinkSize = Qore.bound(3, side * 0.25, 25)`.
- **RTL affects only horizontal** — the handles travel via `visualPosition`
  (mirrored: value-increasing moves left), and the `rangeBox` span stays
  positive via the absolute difference; the track/fill are solid colors, so
  no gradient endpoints need swapping (unlike `Slider`).
- **Vertical ignores RTL** — Qt's vertical slider always shows value
  increasing upward (`visualPosition` is constantly `1 − position`, so a
  `LayoutMirroring` has no effect).
- **Implicit size** swaps with orientation (`150 × 25` ↔ `25 × 150`),
  matching the official "vertical is narrow" convention.
- **Value mapping** is the template default — drag/keys/wheel map x or y
  per orientation, RTL reverses via `visualPosition`. No self-written logic.

## Properties

This control defines **no per-instance color properties** — colors come from
the unified style interface (`Style`), same model as `Slider`. The host
recolors via attached-property propagation (set `Style.accent` /
`Style.buttonText` on this control or any ancestor).

**Color model** — a contrast pair, control foreground → accent:
- Track = `Style.buttonText` at 75% opacity (the name follows the Qt
  palette convention; the semantics is the **control foreground color**)
  with `ThemeHQ.recommendForeground(Style.buttonText)` stroke — contrast-safe
  without host intervention.
- Foreground fill (the crystal spanning the interval) = `Style.accent`.

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates
  the foreground expansion animation (`ItemAnimatedResizer`) and the
  focus-highlight border transition; when off, both switch instantly
  instead of animating.

Inherited from `T.RangeSlider`: `first`, `second` (each a
`RangeSliderHandle` with `value`/`position`/`visualPosition`/`pressed`/
`hovered`), `from`, `to`, `stepSize`, `snapMode`, `live`, and all other
`RangeSlider`/`Control` members (including `first.handle`/`second.handle`,
the template handle plug points). See the Qt documentation for the
inherited members. The implicit size is derived from the template formula
(`background` 150 × 25 vs. the foreground content, whichever is larger),
swapping to 25 × 150 in the vertical orientation.

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

// Custom colors: interval fill, track background — via Style attached-property
// propagation (the stroke follows the track automatically).
RangeSlider {
    width: 300
    Style.accent: Style.active.accent
    Style.buttonText: Style.active.base
}

// Behavior plug: replace the template handles. Positioning is the host's
// responsibility (the template never moves handles) — the non-overlapping
// formula keeps the two strips from intersecting.
RangeSlider {
    width: 300
    first.handle: Rectangle {
        width: height / 2
        height: parent.availableHeight
        radius: 2
        color: Qt.alpha(parent.color, 0.55)
        x: parent.leftPadding
            + parent.first.visualPosition * (parent.availableWidth - width * 2)
        y: parent.topPadding
    }
    second.handle: Rectangle {
        width: height / 2
        height: parent.availableHeight
        radius: 2
        color: Qt.alpha(parent.color, 0.55)
        x: parent.leftPadding + width
            + parent.second.visualPosition * (parent.availableWidth - width * 2)
        y: parent.topPadding
    }
}
```

// Vertical: implicit size swaps to 25×150, the handles travel along y
// (value increases upward), the interval fills bottom → top.
RangeSlider {
    orientation: Qt.Vertical
    width: 40
    height: 300
    Component.onCompleted: setValues(0.25, 0.75)
}
```

## Interaction feedback

- **Dragging** is template behavior: each handle is hit-tested by the
  template (press on the handle, drag; press on the track selects the
  nearest endpoint via the template's `nearest` logic). `snapMode`/
  `stepSize`/`live` are honored exactly as in `T.RangeSlider`. There is no
  overall-interval dragging (the template only moves single endpoints).
- Keyboard stepping (`increase()`/`decrease()`, direction keys after
  focus) steps by `stepSize` with template clamping.
- Expansion feedback: the foreground crystal expands to fill the
  `rangeBox` interval (straight middle = the interval, points overflowing
  `height/2`) while hovered (hover only counts within the crystal shape —
  the `rangeBox` `containmentMask` restricts hit-testing to the crystal)
  or while a recent value change holds (`TimerLatch`,
  `Style.movementDuration × 2` sliding window), then contracts by
  `shrinkSize` (`Qore.bound(3, side * 0.25,
  25)`, `side` = the normal size) when neither holds. The expansion is
  animated (`ItemAnimatedResizer`) unless `animationEnabled` is off.
- Inverted range (`from > to`): positions reverse; the interval stays
  positive (the template guarantees `first.position <= second.position`).
- Narrow/coincident intervals: the crystal's cut follows the shape's own
  geometry (`min(width, height)/2`), so a zero-width interval (coincident
  endpoints) degrades to a crystal (diamond) — no special casing.
- Keyboard focus highlight: while the control holds keyboard focus
  (`visualFocus` — Qt's standard semantic, `true` only when focus was
  acquired through keyboard navigation, i.e. Tab/Backtab/shortcut; mouse,
  programmatic and window-switch focus do not light it), the default track
  border switches to `Style.highlight` and reverts to
  `ThemeHQ.recommendForeground(Style.buttonText)` on losing focus, animated
  under the `animationEnabled` gate. The highlight
  color is fixed (`Style.highlight`, no public property) and lives inside
  the default `background` only — replacing `background` removes it.
  `RangeSlider` is a Qt focus-scope control, but keyboard entry lands on
  the root (the default handles are not separately Tab-focusable), so
  `root.visualFocus` carries the full semantic. Focusability stays at the
  Qt default; the host enables focus the Qt-standard way
  (`activeFocusOnTab` or `forceActiveFocus`).
