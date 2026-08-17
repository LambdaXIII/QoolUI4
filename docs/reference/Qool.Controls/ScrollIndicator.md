# ScrollIndicator

A QoolUI-styled scroll indicator based on `QtQuick.Templates.ScrollIndicator`.

`ScrollIndicator` is a lightweight bar showing the scroll position within a
scrollable area. `color` sets the bar color; `alwaysOn` controls whether it
is permanently shown; `showIndicator` is a read-only state (hidden whenever
the content fits one screen — `size` is 1 —, always shown when `alwaysOn`,
otherwise shown only while the scroll bar is `active` and `size` is below
1.0); `scrollPosition` remaps the native `position`
(`Qore.remap(position, 0, 1 - size)`) so external code can do exact
displacement. The indicator's geometry switches between two `Binding` sets
depending on `horizontal` (vertical bar 2 × 100 / horizontal bar 100 × 2,
with 2 px margins on the relevant sides).

**Deliberate design — two-state drive:** the indicator opacity is driven by a
latch with two states: within a 1750 ms window after scrolling
(`scrollPosition` changes) it is transiently 1, and when the window ends it
falls back to the resting `visualOpacity` (`0.25` when `alwaysOn`, else `0`).
Do not drive `opacity` with imperative assignment — assignment kills the
binding underneath (the binding is permanently lost, and `showIndicator`
changes no longer reach the opacity); the two-state transition is handled by
a `BasicNumberBehavior`.

## Properties

- `color : color` (default `Style.highlight`)
  The indicator bar color.

- `alwaysOn : bool` (default `true`)
  When `true`, the indicator is always shown (except when the content fits
  one screen). When `false`, it is shown only while the scroll bar is
  `active` and `size` is below 1.0.

- `showIndicator : bool` (read-only)
  Effective visibility state: `false` when `size === 1`; `true` when
  `alwaysOn`; otherwise `active && size < 1.0`.

- `scrollPosition : real` (read-only)
  Remapped scroll position — `Qore.remap(position, 0, 1 - size)` — so the
  fully scrolled state maps to the same value regardless of `size`.

- `minimumSize : real` (default `0.1`)
  The smallest the indicator is allowed to shrink (set here on the type).

Inherited from `T.ScrollIndicator`: `position`, `size`, `orientation`,
`horizontal`, `active`, `visible` and all other `ScrollIndicator`/`Control`
members. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from
`T.ScrollIndicator`).

## Methods

This type defines no additional methods (inherits all methods from
`T.ScrollIndicator`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

// Attached to a scrollable: the standard usage.
ListView {
    anchors.fill: parent
    model: 100
    delegate: Text { text: index }

    Q.ScrollIndicator.vertical: Q.ScrollIndicator {}
}

// Always-visible, custom color, exact position binding.
Q.ScrollIndicator {
    horizontal: false
    color: Style.active.highlight
    alwaysOn: true
}
```

> **Note:** in the usage above `Q` is the `Qool.Controls` import alias —
> `ScrollIndicator` is attached to a `Flickable`/`ListView` via
> `Q.ScrollIndicator.vertical` / `.horizontal`, following the official
> `ScrollIndicator` attached-property semantics.
