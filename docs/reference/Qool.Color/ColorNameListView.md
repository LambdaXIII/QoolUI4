# ColorNameListView

A flat, scrollable list of the color names in a category — the
replacement for the removed `ColorNameList`, using `ColorNameButton`
delegates in a `ButtonGroup`.

`ColorNameListView` derives from `ListView`. Its `model` is
`ColorHQ.colorNames(root.category)` — the names of one plugin category
(e.g. `"DEFAULT"`). Each row is a `ColorNameButton` bound to the name's
color (`ColorHQ.color(modelData)`), `checkable`, and grouped so exactly
one row is selected at a time. Clicking a row writes the selected color
to the internal `currentColor` (exposed read-only through
`pCtrl.currentColor`), and the selected name is exposed as
`currentColorName`.

### Selection semantics

- Clicking a row sets `currentColor`; the `checked` decorator follows
  the row's selection through the shared `ButtonGroup`.
- `currentColor` / `currentColorName` are **read-only projections** of the
  internal selection — the host reads them to react (e.g. write into a
  `ColorAssistant`), not to drive the list. There is no external colour →
  selection sync (deselect-on-external-change) as in the removed
  `ColorNameList`; this list is a simple one-way picker.
- The list does **not** carry its own category switcher — a host switches
  `category` (typically via the `ColorHQ.categories()` output) and rebuilds
  the model.

## Properties

- `category : string` (default: `"DEFAULT"`)
  The plugin category whose names are listed; changing it rebuilds the
  model.

- `currentColor : color` (read-only)
  The color of the currently selected row (the last clicked), via the
  internal `SmartObject`.

- `currentColorName : string` (read-only)
  `ColorHQ.colorName(currentColor)` — the nearest name of the selected
  color.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch, forwarded to the delegate buttons.

## Signals

This component defines no additional signals.

## Methods

This component defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: ca
}

ColorNameListView {
    width: 250
    height: 400
    category: "DEFAULT"
    onCurrentColorChanged: ca.color = currentColor
}
```
