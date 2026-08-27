# MenuBar

A QoolUI-styled horizontal menu bar based on `QtQuick.Controls.MenuBar`.

`MenuBar` inherits the official interface — `menus` (list of `Menu`),
`Menu` children, `currentIndex` and the rest work as documented by Qt. The
background is a `QoolBox` with the top-left corner cut by
`Style.menuCutSize` and a 1 px border; the default `delegate` is the Qool
`QoolMenuBarItem`.

## Properties

- `animationEnabled : bool`
  Animation switch, propagated from the host (`parent?.animationEnabled`) and
  falling back to `Style.animationEnabled`. Forwarded to the item delegates.

- `delegate : Component`
  The menu-bar item delegate, defaulting to `QoolMenuBarItem`.

## Notes

- Padding: top/bottom 1, left `Style.menuCutSize`, right 1.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.MenuBar`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.MenuBar`).

## Usage Example

```qml
import QtQuick
import QtQuick.Controls as Quick
import Qool
import Qool.Controls

MenuBar {
    Menu {
        title: "File"
        Quick.Action { text: "Open" }
    }
    Menu {
        title: "Edit"
        Quick.Action { text: "Copy" }
    }
}
```
