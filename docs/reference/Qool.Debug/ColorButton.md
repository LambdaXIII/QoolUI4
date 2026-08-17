# ColorButton

A debug color-picker button: right-click opens a color dialog, double-click resets to the default color.

`ColorButton` displays a label (`name`) whose background color is kept in sync with `value`. It is a debugging tool intended to be embedded in debug panels:

- Right-click opens a `ColorDialog`; accepting the dialog sets `value` to the chosen color.
- Double-click with the left button resets `value` to `defaultValue`.
- Hovering shows a pointing-hand cursor.

The type derives from the internal `DBGControl` base (itself a `T.Control` with a default background). The background color follows `value` through a `Binding` that activates automatically once the background exists — no `when` gate is used.

## Properties

- `value : color` (default `defaultValue`)
  The current color. Updated by the color dialog or by `reset()`; the background color follows it.

- `defaultValue : color` (default `"darkgrey"`)
  The default color that `reset()` restores.

- `name : string`
  The label text displayed on the button.

Inherited from `T.Control` (via `DBGControl`): `padding` (default 4), `background`, `contentItem`, and all other `Control` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `T.Control`).

## Methods

- `void reset()`
  Resets `value` to `defaultValue`.

- `void chooseColor()`
  Opens the color dialog, preselecting the current `value`.

## Usage Example

```qml
import QtQuick
import Qool.Debug

ColorButton {
    name: "Fill"
    value: Style.accent
    defaultValue: Style.negative
    onValueChanged: console.log("color =", value)
}
```
