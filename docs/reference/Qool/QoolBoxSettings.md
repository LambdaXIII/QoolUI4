# QoolBoxSettings

The octagon appearance settings (four corner cuts, border, fill, offset, and the
rounded-corner switch). It is the unified configuration entry for a `QoolBox`'s shape
and appearance; a host accesses it through the `QoolBox.settings` property. It is
also the type of the `QoolBoxShapeControl::settings` property.

All properties are bindable (for example `settings.borderWidth: slider.value`) and
animatable (`Behavior`/`NumberAnimation` act on the fields).

## Reference semantics

`settings` has QObject reference semantics:

- `qbox1.settings: qbox2.settings` shares the same instance — field-level bindings
  and animations act on the shared object, so a change in one place takes effect
  everywhere.
- An independent copy means assigning a new instance (instances do not affect each
  other).

## Default values

The type defaults are C++ constants (`cutSize*`: 0, `borderWidth`: 0, `borderColor`:
`red`, `fillColor`: `yellow`, `offsetX`/`offsetY`: 0, `curved`: `false`). Theme-linked
defaults are implemented by the consumer (`QoolBox`, `QoolBGBox`, and so on) by
explicitly binding `Style` fields at instantiation: a host instantiating directly
gets the current theme's appearance and may override individual fields.

## Properties

- `cutSizeTL` / `cutSizeTR` / `cutSizeBL` / `cutSizeBR` (`real`): the four corner cut
  sizes. Default `0` (right angle).
- `borderWidth` (`real`): the border width. Default `0`.
- `borderColor` (`color`): the border color. Default `red`.
- `fillColor` (`color`): the fill color. Default `yellow`.
- `offsetX` / `offsetY` (`real`): the overall offset. Default `0`.
- `curved` (`bool`): the rounded-corner switch. Default `false`.

## Signals

This type defines no additional signals; each property has the auto-generated
`xxxChanged` signal.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

QoolBox {
    width: 240
    height: 140
    settings: QoolBoxSettings {
        cutSizeTL: 12
        cutSizeTR: 12
        cutSizeBL: 12
        cutSizeBR: 12
        borderWidth: 2
        borderColor: "white"
        fillColor: "black"
        offsetX: 0
        offsetY: 0
        curved: true
    }
}
```
