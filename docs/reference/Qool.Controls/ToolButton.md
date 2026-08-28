# ToolButton

A QoolUI-styled toolbar button — `T.ToolButton` with a `QoolBox` background
and the standard Qool interaction covers.

`ToolButton` provides the standard `T.ToolButton` API (`text`, `checkable`,
`checked`, `enabled`, `pressed`, `clicked()`, `toggled()`, ...) with the
Qool visual: a `QoolBox` background configured by `backgroundSettings`
whose fill/border/corner cuts follow the theme, a plain text content, and
the standard pressed / highlight / locked covers. The first item of a
positioner (e.g. a toolbar `Row`) gets a cut top-left corner — a seamless
leading edge in button groups.

## Properties

- `backgroundSettings : QoolBoxSettings`
  Unified appearance configuration for the background fill, border and the
  corner cuts. Defaults to a `QoolBoxSettings` with `fillColor` =
  `Style.button`, `borderWidth` = `Style.controlBorderWidth`, `borderColor`
  = `Style.controlBorderColor`, and `cutSizeTL` = `5` when this button is
  the first item of a positioner (`Positioner.isFirstItem`) else `0`.

- `isFirst : bool` (read-only)
  `true` when this button is the first item of its positioner parent —
  drives the default `cutSizeTL` (the leading corner cut).

When `checked`, the background fill switches to `Style.highlight`, the
border to `Style.highlightedText`, and the text to `Style.highlightedText`.

Inherited from `T.ToolButton`: `text`, `checked`, `checkable`, `down`,
`pressed`, `hovered`, `enabled`, `icon`, `autoRepeat`, `clicked()`,
`toggled()` and all other `AbstractButton`/`Control` members. See the Qt
documentation for the inherited members. `font.pixelSize` defaults to
`Style.controlTextSize`.

## Signals

This type defines no additional signals (inherits all signals from
`T.ToolButton`, notably `clicked()` and `toggled()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.ToolButton`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

Row {
    ToolButton { text: "Bold"; checkable: true }
    ToolButton { text: "Italic"; checkable: true }
}
```
