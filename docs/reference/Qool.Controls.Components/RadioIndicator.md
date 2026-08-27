# RadioIndicator

A QoolUI radio indicator — an outer ring with a filled inner disc — built
with `Shape` (curved renderer) on the `RectGadget` geometry.

The indicator is a two-layer `ShapePath`: the outer ring is drawn in
`borderColor` (a `PathRectangle` ring of width `borderWidth`), the inner
disc in `color` (shrunk additionally by `borderSpace`).

## Properties

- `width` / `height : real`
  Explicit default logical size `20 × 20`. Note: the shape does **not**
  guarantee equal width and height (`radius` derives from the height).

- `radius : real`
  The outer ring's corner radius. Default `height / 2`.

- `borderWidth : real`
  The outer ring width. Default `2`.

- `borderSpace : real`
  The gap between the outer ring's inner edge and the inner disc. Default
  `2`.

- `color : color`
  The inner disc fill. Default `Style.accent`.

- `borderColor : color`
  The outer ring fill. Default `color` (same as the disc).

## Signals

This type defines no additional signals (inherits the standard
`Shape`/`Item` signals).

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

RadioIndicator {
    width: 18
    height: 18
    color: "white"
    borderColor: "black"
}
```
