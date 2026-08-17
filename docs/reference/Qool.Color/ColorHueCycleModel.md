# ColorHueCycleModel

A cyclic hue-ring model: `number` equally spaced slots, one color per
slot, evenly distributed around the hue ring.

`ColorHueCycleModel` is a `QAbstractListModel` intended as the model
source for hue-ring views such as `HSVWheel`. Each row (slot) exposes five
roles: `color`, `hue`, `saturation`, `value`, `position`.

### Roles

| Role | Type | Meaning |
|---|---|---|
| `color` | `color` | The slot color: `QColor::fromHsvF(hue, saturation, value)` |
| `hue` | `real` | The wrap-folded hue (0..1) |
| `saturation` | `real` | The current saturation (identical on every row) |
| `value` | `real` | The current value (identical on every row) |
| `position` | `real` | The slot's normalized position (0..1) |

Where `position = row / number` and `hue = position + hueOffset`; when the
result leaves 0..1 it wraps around modulo (ring semantics). The 0..1
normalized `position`/`hue` match the `hsvF` family of `ColorAssistant`
and can be fed directly to floating-point `QColor::fromHsvF` style
construction.

### Change semantics

- `number` changes: the slot count changes → the whole model is reset
  (`beginResetModel` / `endResetModel`).
- `hueOffset` changes: all rows emit `dataChanged` for the `hue` and
  `color` roles.
- `saturation` changes: all rows emit `dataChanged` for the `saturation`
  and `color` roles.
- `value` changes: all rows emit `dataChanged` for the `value` and
  `color` roles.

## Properties

- `number : int` (default: `16`)
  The number of equally divided slots — the model's row count. Changing it
  resets the whole model.

- `hueOffset : real` (default: `0`)
  The hue offset, 0..1 normalized; values outside the range wrap around
  automatically (modulo, not clamping).

- `saturation : real` (default: `1`)
  The saturation shared by all rows (0..1).

- `value : real` (default: `1`)
  The value shared by all rows (0..1).

## Signals

- `numberChanged()`
  Emitted when `number` changes (after the model reset).

- `hueOffsetChanged()`
  Emitted when `hueOffset` changes.

- `saturationChanged()`
  Emitted when `saturation` changes.

- `valueChanged()`
  Emitted when `value` changes.

## Methods

The type exposes the standard `QAbstractListModel` interface; the row data
is read through the roles above. It defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

Repeater {
    model: ColorHueCycleModel {
        number: 12
        hueOffset: 0.25
        saturation: 1.0
        value: 1.0
    }

    delegate: Rectangle {
        width: 24
        height: 24
        radius: 12
        color: model.color
        // model.hue / model.position are also available
    }
}
```
