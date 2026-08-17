# CutSizeBinding

A binding utility that synchronizes corner cut sizes (`cutSize*`) between a
source and a target object.

`CutSizeBinding` reads the `cutSizeTL`/`TR`/`BL`/`BR` properties of `from`
and writes them to the corresponding properties of `to`. With `bindingMode`
set to `AllCorners` (default), all four corners are synchronized; with
`TopLeftCornerOnly`, only the top-left corner is synchronized.

A binding is inactive when `when` is `false`, or when either the source or
the target lacks the corresponding property. It is used to keep corner cut
sizes consistent across objects (for example two `QoolBoxSettings`
instances); the source/target may be any object exposing
`cutSizeTL`/`TR`/`BL`/`BR`.

## Properties

- `from : var`
  The source object exposing `cutSizeTL`/`TR`/`BL`/`BR`. When unset, no
  binding is active.

- `to : var`
  The target object whose `cutSize*` properties are written. When unset, no
  binding is active.

- `bindingMode : int` (default `CutSizeBinding.AllCorners`)
  Which corners to synchronize.
  - `CutSizeBinding.AllCorners` — all four corners (default).
  - `CutSizeBinding.TopLeftCornerOnly` — only the top-left corner.

- `when : bool` (default `true`)
  Master switch. When `false`, no binding is active.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

// Keep two QoolBoxSettings' corners in sync.
CutSizeBinding {
    from: sourceSettings
    to: targetSettings
    bindingMode: CutSizeBinding.AllCorners
}
```
