# QoolMenuBarItem

A QoolUI-styled menu-bar item based on `QtQuick.Controls.MenuBarItem`, used
as the default `MenuBar.delegate`.

`QoolMenuBarItem` inherits the official interface — `text`, `highlighted`,
`enabled`, `menu` and the rest work as documented by Qt. The highlight is a
bottom underline (`HorizontalBar` filling to `percentage` 1 on
`highlighted`) in the current text color.

## Properties

- `animationEnabled : bool`
  Animation switch, propagated from the host (`parent?.animationEnabled`) and
  falling back to `Style.animationEnabled`.

## Notes

- Text color states: `enabled` + `highlighted` → `Style.highlight`;
  `enabled` only → `Style.buttonText`; disabled → `Style.negative`. The
  color animates with `BasicColorBehavior` when animation is enabled.
- Font: `Style.controlTextSize`.

## Signals

This type defines no additional signals (inherits all signals from
`QtQuick.Controls.MenuBarItem`).

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.MenuBarItem`).

## Usage Example

Usually no direct use: `MenuBar` instantiates it as its default delegate.

```qml
import QtQuick
import Qool
import Qool.Controls.Components

QoolMenuBarItem {
    text: "File"
}
```
