# Menu

A QoolUI-styled popup menu based on `QtQuick.Controls.Menu`.

`Menu` inherits the full official interface — `title`, `Action` items,
nested `Menu` (submenus), `checkable`/`checked` actions, `delegate`,
`popup()`, `open()` and the rest all work as documented by Qt. On top of it
the appearance is unified with the Qool style: the popup background is a
`QoolBGBox` (octagonal, `cutSizeTL`-cut) whose padding is composed from the
box's `*Space` properties, and the default `delegate` is the Qool `MenuItem`.

## Properties

- `animationEnabled : bool`
  Animation switch, propagated from the host (`parent?.animationEnabled`) and
  falling back to `Style.animationEnabled`.

- `showTitle : bool`
  Whether the menu title is rendered by the background `QoolBGBox`. Defaults
  to `!(isInMenuBar || isSubMenu)` — a menu-bar top-level menu or a submenu
  hides its title by default, keeping the usual Qt menu behavior; a
  standalone (context) menu shows it. When `showTitle` is `true`, the
  background's `cutSizeTL` is `Style.menuCutSize` (else 0).

- `settings : QoolBoxSettings`
  Background appearance. Defaults to `borderWidth` =
  `Style.controlBorderWidth`, `borderColor` = `Style.controlBorderColor`,
  `fillColor` = `Style.controlBackgroundColor`, `cutSizeTL` =
  `showTitle ? Style.menuCutSize : 0`.

- `delegate : Component`
  The item delegate, defaulting to the Qool `MenuItem`.

## Notes

- The menu's own `topInset` is 4 when attached to a menu bar (to clear the
  bar's bottom border), else 0.
- `popupType: Popup.Window` is not recommended: checkable `Action`s have
  issues in a windowed popup.
- The delegate's `Action`/`MenuItem` contract (text, `checkable`,
  `enabled`, `subMenu`, `highlighted`) is the official one.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.Menu`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.Menu`, notably `popup()` and `open()`).

## Usage Example

```qml
import QtQuick
import QtQuick.Controls as Quick
import Qool
import Qool.Controls

Menu {
    title: "File"
    Quick.Action {
        text: "Open"
        onTriggered: console.log("open")
    }
    Quick.Action {
        text: "Save"
        checkable: true
    }
    Menu {
        title: "Recent"
        Quick.Action { text: "a.txt" }
    }
}
```
