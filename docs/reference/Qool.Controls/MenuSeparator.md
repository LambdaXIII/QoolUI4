# MenuSeparator

A QoolUI-styled menu separator based on `QtQuick.Controls.MenuSeparator`,
optionally carrying a caption.

`MenuSeparator` renders a horizontal rule with an optional centered text:
without `text` a plain line; with `text` the line splits into two segments
flanking the caption.

## Properties

- `text : string`
  Optional caption. Empty (default) renders a plain separator line.

- `color : color`
  Line and caption color. Default `Style.alternateBase`.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.MenuSeparator`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.MenuSeparator`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

MenuSeparator {
    text: "Cool section"
}
```
