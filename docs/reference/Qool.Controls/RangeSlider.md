# RangeSlider

An interval slider: a hexagonal track with crystal triangle handles and an
accent-filled selection region (the interval version of `Slider`).

`RangeSlider` lets the user select a value range. `first` and `second`
handles delimit the interval (template properties; the interface is
compatible with `QtQuick.Templates.RangeSlider` — click jumps to the nearest
handle, drag is continuous, keyboard steps the active handle: all official
behavior). The track is a `Crystal` hexagon (`Style.text` base color, **no
gradient**); the selected region between `first` and `second` is filled as a
flat-cut rectangle with `color` (default `Style.accent`). The handles are
`HalfCrystal` triangles — `first` points left, `second` points right; their
flat edges face each other clamping the selected segment, and the tips point
outward toward each unselected side.

## Properties

- `color : color` (default `Style.accent`)
  The selection fill color — and the `second` handle color. The host changes
  the whole selected-region visual by changing this one property. The track
  base stays fixed at `Style.text`. Handle segment-color sampling: the
  `first` handle is fixed to `Style.text` (base-segment color), the `second`
  handle to `color` (selected-segment color).

- `justMoved : bool`
  "A value was just written" declarative latch window — 500 ms, sliding
  (continuous changes keep it held). `true` while any value change is within
  the window.

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`.

- `preferredHeight : real` (read-only)
  Resting height of the crystal track and handles (contracted state)
  — `root.height - Qore.bound(3, root.height * 0.25, 25)`. When expanded the
  handles fill the control's full height. Usable by the host in external
  layout calculations.

Inherited from `T.RangeSlider`: `first`, `second` (each a `RangeSliderHandle`
with `value`/`position`/`pressed`), `from`, `to`, `stepSize`, `snapMode`,
`live`, `active`, and all other `RangeSlider`/`Control` members. See the Qt
documentation for the inherited members. The default implicit size is
80 × 25.

## Signals

This type defines no additional signals (inherits all signals from
`T.RangeSlider`).

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

// Custom selection color.
RangeSlider {
    width: 300
    color: Style.active.accent
}
```

## Interaction feedback

- Hover / press / just-moved (the 500 ms window after any value change): the
  corresponding handle expands to the control's full height (resting =
  `preferredHeight` — `Qore.bound(3, height × 0.25, 25)`; the track and
  handles share the same resting height and stay center-aligned; the triangle
  tip rests inside the track and pushes to the track end when expanded),
  animated under the `animationEnabled` gate. The hover cursor becomes a
  horizontal double-arrow (only when `enabled`).
- Programmatic writes to `first.value`/`second.value` (e.g. an external
  binding): both handles expand for about 500 ms (`justMoved` — "a value was
  written gets feedback", regardless of who wrote it); continuous changes
  keep the window sliding.
- Inverted range (`from > to`): positions reverse; the selection and handles
  follow automatically.

The `first`/`second` handle delegates must self-write their `x`/`y` (the
`T.RangeSlider` template does not inject positioning — official convention,
same as `Slider`). The expanded handle state fills the control height (never
exceeds the bounds) — `clip` or not does not affect the feedback.
