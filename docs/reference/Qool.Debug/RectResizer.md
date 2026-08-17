# RectResizer

A six-handle resize frame: dragging the handles adjusts the geometry of the host (the parent item).

`RectResizer` is a debug decoration control. Six handles rendered by `Floater` contents surround the host — left/right handles resize the width, top/bottom handles resize the height, and the four corner handles resize in both directions. Dragging directly assigns the host's `x`/`y`/`width`/`height`; this is debug semantics — the assignments break any existing geometry bindings on the host, and the host itself decides whether that is acceptable.

Handle positions are tracked automatically by the `PositionTracker` built into `Floater`, which follows the ancestor chain — translation, scaling and rotation of the host all trigger a recomputation, so no manual refresh is needed.

## Properties

- `color : color` (default `Style.toolTipBase`)
  The handle color.

- `spacing : real` (default 20)
  The gap between the handles and the host edges.

- `handleWidth : real` (default 10)
  The handle thickness. Corner handles are 1.5 times this value.

Inherited from `Item`: `visible`, `enabled`, `opacity`, and all other `Item` properties. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from `Item`).

## Methods

This type defines no additional methods (inherits all methods from `Item`).

## Usage Example

Declare it as a child of the target; `anchors.fill: parent` is built in, so the handles wrap the host automatically.

```qml
import QtQuick.Controls
import Qool.Debug

Dial {
    RectResizer {}
}
```
