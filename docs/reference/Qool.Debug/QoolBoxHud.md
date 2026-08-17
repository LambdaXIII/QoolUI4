# QoolBoxHud

A QoolBox-specific debug overlay showing the 16 external/internal control points (`ext*` / `int*`).

`QoolBoxHud` renders one `PointIndicator` per control point exposed by `QoolBox.control`: eight external points (`extTL`/`extTR`/`extBL`/`extBR`/`extLT`/`extLB`/`extRT`/`extRB`, colored `Style.positive`) and eight internal points (`intTL`/`intTR`/`intBL`/`intBR`/`intLT`/`intLB`/`intRT`/`intRB`, colored `Style.negative`).

It must be used as a **direct child of a `QoolBox`**: the `box` property defaults to `parent` and its type requires a `QoolBox`. Attaching the HUD to a non-`QoolBox` parent leaves `box` null and the HUD stops working — a visible misconfiguration, consistent with the debug boundary-exposure principle (misconfiguration is exposed immediately rather than silently degraded). The overlay consumes only the public surface of `QoolBox` (`box.control`); it has no white-box contract with the shape internals.

## Properties

- `box : QoolBox` (default `parent`)
  The target `QoolBox` whose control points are displayed. Must be the direct parent.

- `showIntPoints : bool` (default `true`)
  Whether the internal control points (`int*`) are shown.

- `showExtPoints : bool` (default `true`)
  Whether the external control points (`ext*`) are shown.

Inherited from `Item`: `visible`, `enabled`, `opacity`, and all other `Item` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `Item`).

## Methods

This type defines no additional methods (inherits all methods from `Item`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Debug

QoolBox {
    width: 200
    height: 120

    // Direct child: `box` picks up `parent`.
    QoolBoxHud {
        showExtPoints: true
        showIntPoints: true
    }
}
```
