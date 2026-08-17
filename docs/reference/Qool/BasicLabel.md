# BasicLabel

A text label control with a `QoolBox` background.

`BasicLabel` derives from `T.Control`. It renders a single-line text label
whose background is a `QoolBox` with uniformly rounded corners
(`cutSizeTL`/`TR`/`BL`/`BR` = 4). The text color is computed automatically as
a contrast foreground against the current `color` and the active `Style`
light/dark backgrounds, so the label stays readable on either theme.

The background appearance can be overridden through `backgroundSettings`.

## Properties

- `text : string` (alias to the internal `Text.text`)
  Holds the label text.

- `color : color` (default `Style.accent`)
  The fill color of the background and the base of the text color.
  The displayed text color is `ThemeHQ.recommendForeground(color,
  Style.light, Style.dark)` — a black/white contrast color chosen against
  this property, taking the current theme's light/dark backgrounds into
  account.

- `backgroundSettings` (alias to the `QoolBox.settings`)
  Overrides the background appearance. When unset, the background uses the
  default `QoolBox` settings with all four corner cut sizes set to 4, the
  border color equal to the computed text color, and the fill color equal to
  `color`.

Inherited from `T.Control`: `font`, `padding`, `leftPadding`, `rightPadding`,
`implicitWidth`, `implicitHeight`, and all other `Control` properties. See
the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from
`T.Control`).

## Methods

This type defines no additional methods (inherits all methods from
`T.Control`).

## Usage Example

```qml
import QtQuick
import Qool

BasicLabel {
    text: "Open"
    color: Style.accent
    // font size follows Style.controlTextSize by default
}
```
