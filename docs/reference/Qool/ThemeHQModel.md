# ThemeHQModel

A theme overview list model (an ordinary type, not a singleton).

`ThemeHQModel` derives from `QIdentityProxyModel` and attaches the theme
database (`ThemeDB` global singleton) as its source model on construction —
bind it directly to a view's `model` property to display all installed
themes (row = theme). The roles match the source model:

| Role | Content |
|------|---------|
| `name` | Theme name (`display` has the same value) |
| `theme` | The full theme value (`Theme`) |
| `metadata` | The metadata mapping |
| `constants` / `active` / `inactive` / `disabled` / `custom` | Flat mappings of the corresponding groups |

> **Note:** The `metadata` role currently returns empty — the source model's
> `data()` does not provide a value for it. A view needing metadata should
> use the `theme` role and read it through `Theme`'s `metadata()` method.

## Live updates

Installing a theme (`installTheme`) makes the source model emit
`rowsInserted`, forwarded natively through `QAbstractProxyModel` — views need
no manual refresh. Other change notifications (`dataChanged`/`modelReset`
etc.) forward the same way. In multi-view scenarios each view instantiates
this type; the data is always consistent (same source model).

## Properties

This type defines no additional properties. It exposes the standard model
roles listed above plus all `QAbstractItemModel`/`QIdentityProxyModel`
members (e.g. `rowCount`, `data`, `roleNames`).

## Signals

This type defines no additional signals. It inherits the standard model
signals (`rowsInserted`, `rowsRemoved`, `dataChanged`, `modelReset`, …) from
`QAbstractItemModel`.

## Methods

This type defines no additional methods. It inherits the standard
`QAbstractItemModel`/`QIdentityProxyModel` methods.

## Usage Example

```qml
import QtQuick
import QtQuick.Controls
import Qool

ListView {
    model: ThemeHQModel {}       // one row per installed theme
    delegate: Text {
        text: name               // 'name' role == 'display'
    }
}
```
