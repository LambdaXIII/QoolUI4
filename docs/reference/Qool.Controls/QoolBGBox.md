# QoolBGBox

A QoolUI background box with an optional title label, for use as a control
`background`.

`QoolBGBox` derives from `QoolBox` and renders the octagonal background box
whose appearance is configured through `settings` (a `QoolBoxSettings`:
border, fill, corner cuts). `title` is rendered by the default `label` (a
`BasicControlTitleText`) at the top of the box; the host can replace
`label` wholesale with any `Item`.

## Properties

- `title : string`
  The title text, rendered by the default `label` at the top of the box.

- `label : Item`
  The title component, replaceable wholesale. The default is a
  `BasicControlTitleText` bound to `title`, `visible: text !== ""` and
  `color: settings.borderColor`. The property object must attach its parent
  explicitly (`parent: root`): QML property objects do not automatically
  become children of the declaring object — without a parent, the effective
  visibility is always false (`visible` is an effective-visibility
  semantics) and all label-visibility logic silently fails.

- `settings : QoolBoxSettings`
  The background appearance. Defaults to `borderWidth` =
  `Style.controlBorderWidth`, `borderColor` = `Style.controlBorderColor`,
  `fillColor` = `Style.controlBackgroundColor`, `cutSizeTL` =
  `Style.controlCutSize` (the other three cuts 0).

- `topSpace`, `leftSpace`, `rightSpace`, `bottomSpace : real` (read-only)
  The padding the control content should give way (for the host's `padding`
  composition):
  - `topSpace` = label height + border width (when the label is visible),
    otherwise just the border width;
  - `left`/`rightSpace` = border width when the label is visible, otherwise
    `control.leftSpace`/`control.rightSpace`;
  - `bottomSpace` = `control.bottomSpace` when the label is visible,
    otherwise 0.
  All through the `label?.visible` null-safety check — an unset `label` is
  `undefined` and always treated as "no label". The label is mounted into the
  top reserved area via a `Binding`, its width capped at the available
  width, right-aligned.

Inherited from `QoolBox`: `fillItem`, `fillGradient`, `control`, `shape`,
`animatingHint` and the four `control`-forwarded `*Space` properties (which
this type overrides with the label-aware versions above). See the `QoolBox`
reference for the inherited members.

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
    label: Text {
        parent: root
        text: "🔊 Level"
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
