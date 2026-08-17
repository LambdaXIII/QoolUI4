# ScrollView

A scroll view with Qool-themed scroll bars — the official `ScrollView`
finished product (Controls version) plus preset Qool-themed scroll bars.

`ScrollView` is Qool's scroll view: all the behavior of the official Qt
Quick Controls `ScrollView` (automatic content-size hookup, background does
not scroll with the content, automatic clipping, scroll forwarding) plus
preset Qool-themed scroll bars (both vertical and horizontal are Qool
`ScrollBar` — not the Qt default style) — the host gets Qool-themed scrolling
(drag / wheel / themed appearance) with zero configuration.

## Properties

- `rightPadding`, `bottomPadding` (overridden defaults)
  Content giving-way: when a scroll bar is visible, the content area deducts
  the bar's size (`rightPadding = effectiveScrollBarWidth + padding`,
  `bottomPadding = effectiveScrollBarHeight + padding`) — the scroll bars
  never cover the content, consistently across styles (the official Basic
  style has no such setting; this type declares it explicitly).

Inherited from `QtQuick.Controls.ScrollView` (which inherits `Pane`): the
official API is fully available — `contentData`, `effectiveScrollBarWidth`,
`effectiveScrollBarHeight`, the `ScrollBar.vertical`/`ScrollBar.horizontal`
attached properties, `ScrollBar.policy`-driven behavior, `padding` and all
other `ScrollView`/`Pane`/`Control` members. See the Qt documentation for
the inherited members. This type does not change official behavior; it only
presets the scroll bars and the content giving-way.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.ScrollView`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.ScrollView`).

## Usage Example

```qml
import QtQuick
import Qool.Controls

ScrollView {
    width: 300
    height: 200
    clip: true

    TextArea {
        text: "Scrollable content"
    }
}

// Scroll bar policy via the official attached property.
ScrollView {
    anchors.fill: parent
    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
}
```

## Behavior

- The content area gives way automatically: when scroll bars are visible the
  content width/height deducts the bars' footprint
  (`rightPadding`/`bottomPadding` = bar size + padding) — bars never cover
  the content, consistently across styles.
- Scroll-bar policy is controlled through the official `policy` property:
  with `AlwaysOff` the bar is fully hidden and the content area does not
  shrink (the `effectiveScrollBar*` sizes go to zero and the giving-way
  disappears automatically).
- The default size is content-driven (official `ScrollView` behavior): with
  no content the implicit size is 0 — the host should give a size
  (`width`/`height` or `anchors.fill`).

## Scroll bars

The built-in vertical/horizontal scroll bars are both Qool `ScrollBar`
(themed, interactively draggable). The default policy is `AsNeeded`
(hidden when the content fits the viewport); the layout follows the official
`ScrollView` style formulas (vertical bar on the right, horizontal bar at
the bottom, full content-area height/width, the two bars yielding to each
other). The bars are instances of the official `ScrollView` attached
properties — hosts access them with the official `ScrollBar.vertical` /
`ScrollBar.horizontal` attached semantics.
