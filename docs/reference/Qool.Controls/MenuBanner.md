# MenuBanner

A QoolUI menu banner — a `MenuSeparator` subclass with a filled, rounded
background — for highlighting a section inside a `Menu`.

`MenuBanner` renders the caption on a `Rectangle` background whose border and
text share the banner color (auto-contrasted against the fill via
`ThemeHQ.recommendForeground`). The corner radius follows `Style.menuCutSize`.

## Properties

- `text : string`
  The banner caption.

- `color : color`
  The banner fill color. Default `Style.accent`.

- `textColor : color`
  The text and border color. Default
  `ThemeHQ.recommendForeground(color)` (auto contrast).

- `borderWidth : real`
  The banner border width. Default `1`.

- `horizontalAlignment`, `verticalAlignment : int`
  Text alignment (aliases to the inner `Text`). Defaults: horizontal center,
  vertical center.

- `elide`, `wrapMode`, `textFormat`
  Aliases to the inner `Text` (`wrapMode` defaults to
  `Text.WrapAtWordBoundaryOrAnywhere`).

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

Menu {
    MenuBanner {
        text: "Section title"
    }
    Quick.Action {
        text: "Item"
    }
}
```
