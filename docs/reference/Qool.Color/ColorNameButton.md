# ColorNameButton

A button presenting a single color swatch plus the nearest color name,
used as the delegate of `ColorNameListView`.

`ColorNameButton` derives from `QtQuick.Controls` `AbstractButton`, so it
inherits the full button contract — `checkable` / `checked`, `down`,
`hovered`, `enabled`, `clicked()`, and the `checkedChanged` signal. The
swatch and name are rendered by the internal
`ColorNameButtonSurface`; the button wires its state to the surface:

- **Name**: `text` resolves to `ColorHQ.colorName(root.color)` — the
  nearest name for the color (falling back to the `#RRGGBB` /
  `#AARRGGBB` text when no provider knows it).
- **Foreground contrast**: the swatch's inner tint and border use
  `ThemeHQ.recommendForeground(color, keepItBright, keepItDark)` — the v4
  foreground facility picking the readable side of the swatch color.
- **State rendering**: `down` thickens the border (`4` vs `2`) and tints
  the fill; `hovered` raises the swatch opacity; `checkable && checked`
  marks the surface `highlighted`, which expands it to the full row and
  reveals the border. `!enabled` forces the surface's text/border color to
  `Style.negative` (dimmed).

## Properties

- `color : color` (default: `"white"`)
  The swatch color; the button name and contrast derive from it.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch, forwarded to the surface.

Inherited from `AbstractButton`: `text`, `font`, `checkable`, `checked`,
`down`, `hovered`, `enabled`, plus all `AbstractButton` members. See the
Qt documentation for the inherited members.

## Signals

This component defines no additional signals (inherits
`AbstractButton.clicked()`, `toggled()`, and `checkedChanged()`).

## Methods

This component defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

// Standalone swatch button — not checkable, shows the color name.
ColorNameButton {
    color: "red"
    onClicked: console.log("picked", color)
}

// As a selectable list delegate (checkable + ButtonGroup).
ButtonGroup { id: group }
ListView {
    model: ["red", "green", "blue"]
    delegate: ColorNameButton {
        required property string modelData
        color: ColorHQ.color(modelData)
        text: modelData
        checkable: true
        ButtonGroup.group: group
        width: ListView.view.width
        onCheckedChanged: if (checked)
            someTarget.currentColor = color
    }
}
```
