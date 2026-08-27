# QoolBGBox

A QoolUI background box with an optional title item, for use as a control
`background`.

`QoolBGBox` derives from `QoolBox` and renders the octagonal background box
whose appearance is configured through `settings` (a `QoolBoxSettings`:
border, fill, corner cuts). `title` is rendered by the default `titleItem`
(a `BasicControlTitleText`) at the top of the box; the host can replace
`titleItem` wholesale with any `Item`.

## Properties

- `title : string`
  The title text, rendered by the default `titleItem` at the top of the box.

- `titleItem : Item`
  The title component, replaceable wholesale. The default is a
  `BasicControlTitleText` bound to `title`, `visible: text && text !== ""`,
  `color: settings.borderColor`, anchored to the box's top-right corner
  (`topMargin`/`rightMargin` = `borderSpace` + `cutSizeTR`, `leftMargin` =
  `borderSpace` + `cutSizeTL`). A `Binding` mounts it on `root` as a child
  when set. The title item owns its own position and visibility: `topSpace`
  reads `titleItem.y + titleItem.height` when the item is visible.

- `settings : QoolBoxSettings`
  The background appearance. Defaults to `borderWidth` =
  `Style.controlBorderWidth`, `borderColor` = `Style.controlBorderColor`,
  `fillColor` = `Style.controlBackgroundColor`, `cutSizeTL` =
  `Style.controlCutSize` (the other three cuts 0).

- `topSpace : real` (read-only)
  The padding the control content should give way at the top:
  `Math.max(labelTopSpace, cutSpaceOnTop) + borderSpace`, where
  `labelTopSpace` = `titleItem.y + titleItem.height` when `titleItem` is
  visible (else 0) and `borderSpace` = `settings.borderWidth + 1`.
  `cutSpaceOnTop` = `max(cutSizeTL, cutSizeTR)` (a `QoolBoxSettings`
  read-only helper, see `QoolBoxSettings`).

- `leftSpace` / `rightSpace : real` (read-only)
  The horizontal padding, equal to `borderSpace` = `settings.borderWidth +
  1`.

- `bottomSpace : real` (read-only)
  The bottom padding, `cutSpaceOnBottom + borderSpace` (the bottom cut
  avoidance plus the border space), where `cutSpaceOnBottom` =
  `max(cutSizeBL, cutSizeBR)`.

- `contentBoundingRect : rect` (read-only alias)
  The content measurement reference: a `DummyItem` whose
  `x = borderSpace`, `y = topSpace`, `width = width − 2·borderSpace`,
  `height = height − topSpace − bottomSpace`. Use it as the safe content
  region for measurement only — it participates in neither layout nor
  implicit size.

- `implicitHeight : real`
  `max(titleItem.y + titleItem.implicitHeight, cutSpaceOnTop)` — the title
  space (regardless of visibility) or the top cut avoidance, whichever is
  larger.

- `implicitWidth : real`
  `max(cutSpaceOnLeft + cutSpaceOnRight, titleItem.implicitWidth)`.

Inherited from `QoolBox`: `fillItem`, `fillGradient`, `control`, `shape`,
`animatingHint` and the four `control`-forwarded `*Space` properties (which
this type overrides with the label-aware versions above). See the `QoolBox`
reference for the inherited members.

## Visibility semantics

`hasLabel` is decided by `titleItem.visible` — an *effective* visibility
(affected by the window attachment): offscreen (no window) it is always
`false`, so the title never participates in `topSpace` until the box is
shown in a window. An unset/`null` `titleItem` is treated as "no title" via
the null-safe check.

## Signals

This type defines no additional signals (inherits all signals from
`QoolBox`).

## Methods

This type defines no additional methods (inherits all methods from
`QoolBox`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

QoolBGBox {
    width: 200
    height: 50
    title: "Volume"
}

// Custom title item.
QoolBGBox {
    width: 200
    height: 60
    titleItem: Text {
        parent: root
        text: "Level"
        color: root.settings.borderColor
    }
}

// Typical control background usage: the host composes padding from the
// space properties.
T.AbstractButton {
    id: button
    property QoolBoxSettings backgroundSettings: QoolBoxSettings {}
    background: QoolBGBox {
        settings: button.backgroundSettings
    }
    topPadding: background.topSpace + 2
    leftPadding: background.leftSpace + 4
    rightPadding: background.rightSpace + 4
    bottomPadding: background.bottomSpace + 2
}
```
