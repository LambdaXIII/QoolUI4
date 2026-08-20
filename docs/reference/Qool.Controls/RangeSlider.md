# RangeSlider

An interval slider built on the `T.RangeSlider` template: template
`first`/`second` handles (transparent narrow strips by default, activating
the template interaction state machine), a static `Crystal` track, and a
foreground crystal hosted in a `rangeBox` inside the `contentItem` that
follows the interval geometry and expands on hover. The selected interval
is displayed as one unified shape — left point + straight middle + right
point.

`RangeSlider` keeps the full `T.RangeSlider` API (`first`/`second` values,
`from`, `to`, `stepSize`, `snapMode`, `live`, `setValues()`). The default
handles activate the template interaction, so **snap, live, keyboard
stepping, nearest click behavior and endpoint clamping are all template
behavior** — nothing is re-implemented.

- **Track** — a static `Crystal` hexagonal track (`backgroundColor` at 75%
  opacity, `borderColor` stroke) in the `background`, full-width, held at
  the rest height and vertically centered. It does not participate in
  interaction feedback (the visual focus is on the foreground).
- **Handles** — `first.handle`/`second.handle` default to transparent
  strips (`width = height / 2`). Their positioning uses a
  non-overlapping formula: the travel is `availableWidth − width × 2`
  (both handles' widths deducted), `first` starts at `0`, `second` at
  `width` — so the two never intersect at any value. Positioning uses
  `visualPosition` (RTL/vertical-aware). Replacing them with any `Item` is
  **behavior plugging** (template handle contract) — the positioning
  binding is the host's responsibility, the template never moves handles.
- **Foreground** — a `Crystal` hosted in `rangeBox` (an `Item` inside the
  `contentItem`). `rangeBox` maps the interval: `x` from `first`'s visual
  position, `width = interval visual width + height` (the extra `height`
  leaves room for the point overflow). The foreground expands to the
  `rangeBox` size on hover (via `ItemAnimatedResizer`) and contracts to
  `size − shrinkSize` at rest.

## Properties

- `color : color` (default `Style.accent`)
  The foreground fill color (the crystal spanning the interval).
- `backgroundColor : color` (default `Style.buttonText`)
  The track background color (rendered at 75% opacity by the default
  track).
- `borderColor : color` (default `ThemeHQ.recommendForeground(backgroundColor)`)
  The stroke color of the foreground crystal and the track.
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates
  the foreground expansion animation (`ItemAnimatedResizer`); when off,
  the resize jumps instead of animating.

Inherited from `T.RangeSlider`: `first`, `second` (each a
`RangeSliderHandle` with `value`/`position`/`visualPosition`/`pressed`/
`hovered`), `from`, `to`, `stepSize`, `snapMode`, `live`, and all other
`RangeSlider`/`Control` members (including `first.handle`/`second.handle`,
the template handle plug points). See the Qt documentation for the
inherited members. The implicit size is derived from the template formula
(`background` 200 × 22 vs. the foreground content, whichever is larger).

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

## Interaction feedback

- **Dragging** is template behavior: each handle is hit-tested by the
  template (press on the handle, drag; press on the track selects the
  nearest endpoint via the template's `nearest` logic). `snapMode`/
  `stepSize`/`live` are honored exactly as in `T.RangeSlider`. There is no
  overall-interval dragging (the template only moves single endpoints).
- Keyboard stepping (`increase()`/`decrease()`, direction keys after
  focus) steps by `stepSize` with template clamping.
- Expansion feedback: while the foreground is hovered, the foreground
  crystal expands to fill the `rangeBox` interval (straight middle = the
  interval, points overflowing `height/2`); at rest it contracts by
  `shrinkSize` (`Qore.bound(3, height * 0.25, 25)`). The expansion is
  animated (`ItemAnimatedResizer`) unless `animationEnabled` is off.
- Inverted range (`from > to`): positions reverse; the interval stays
  positive (the template guarantees `first.position <= second.position`).
- Narrow/coincident intervals: the crystal's cut follows the shape's own
  geometry (`min(width, height)/2`), so a zero-width interval (coincident
  endpoints) degrades to a crystal (diamond) — no special casing.
