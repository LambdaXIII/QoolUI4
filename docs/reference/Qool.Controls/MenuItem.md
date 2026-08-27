# MenuItem

A QoolUI-styled menu item based on `QtQuick.Controls.MenuItem`, used as the
default `Menu.delegate`.

`MenuItem` inherits the official interface — `text`, `checkable`/`checked`,
`enabled`, `highlighted`, `subMenu`, `action`, `shortcut` and the rest work
as documented by Qt. The visual state machine: a highlighted item shows an
`accent`-tinted left bar; a checked item shows a `RadioIndicator` (filled
with `Style.highlight`); a submenu item shows a right-pointing `HalfCrystal`
arrow; a pressed item is dimmed by a `ControlPressedCover`; a disabled item
is locked by a `ControlLockedCover` and its text turns `Style.negative`.

## Properties

- `animationEnabled : bool`
  Animation switch, propagated from the host (`parent?.animationEnabled`) and
  falling back to `Style.animationEnabled`.

## Notes

- Text color states: `enabled` + `highlighted` → `Style.accent`;
  `enabled` only → `Style.buttonText`; disabled → `Style.negative`.
- Font: `Style.controlTextSize - 2`.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.MenuItem`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.MenuItem`).

## Usage Example

Usually no direct use: `Menu` instantiates it as its default delegate.

```qml
import QtQuick
import Qool
import Qool.Controls

MenuItem {
    text: "Copy"
    shortcut: "Ctrl+C"
    onTriggered: console.log("copy")
}
```
