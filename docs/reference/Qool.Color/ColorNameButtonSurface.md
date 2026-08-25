# ColorNameButtonSurface

The low-level visual surface of a color-name button — a color swatch
block with the name text beside it, expanding to the full row when
highlighted. This is the building block behind `ColorNameButton`; it
deliberately exposes only visual options (no button semantics) so a host
can reuse the exact swatch-surface treatment without inheritance.

`ColorNameButtonSurface` renders a solid-colored block (`color`) with a
`1px` border (`borderColor`) and the name text from `colorName`. Its
distinctive behavior is the **highlight expansion**:

- **Unhighlighted**: the swatch is a small square sized to the text
  height (minus `indicatorShrinkSize * 2`), sitting at the left; the name
  text is indented past it (`smallBox.x + smallBox.width + spacing`).
- **Highlighted**: the swatch grows to the full component bounds
  (`bigBox`) and the text starts flush at the component left (`x: 0`).
  The `nameText.x` transition animates this gap, and the swatch's
  geometry (x/y/width/height) animates through the shared
  `GeoLocker` that locks the rectangle to either `smallBox` or `bigBox`.

The expansion is the visual "selected" cue consumed by
`ColorNameButton` (via `highlighted: checkable && checked`); the elastic
swatch animation (`Easing.OutElastic`) is the intentional signature of
the selected state, while the text uses a smooth `Easing.InOutQuart`.

The component is deliberately minimal — it is a *surface*, not a control:
it has no `clicked` signal and no `checkable` state of its own.

## Properties

- `color : color` (required)
  The swatch fill color; also the input to `ThemeHQ.recommendForeground`
  (via `pCtrl.foregroundColor`) when `borderColor` is left default.

- `colorName : string` (required)
  The name text shown beside the swatch.

- `highlighted : bool` (default: `false`)
  Whether the swatch is expanded to the full row (the "selected" cue).

- `borderColor : color` (default:
  `ThemeHQ.recommendForeground(root.color)`)
  The swatch border color — read from the color's foreground contrast.

- `textColor : color` (default: `Style.buttonText`)
  The name text color when not highlighted.

- `spacing : real` (default: `8`)
  The gap between the swatch indicator and the name text (and between
  the text and the component right edge).

- `indicatorShrinkSize : real` (default: `4`)
  The swatch's height is the text height minus `2 * indicatorShrinkSize`,
  giving `2 * indicatorShrinkSize` vertical padding.

- `font : font` (default: inherits `ColorNumText`'s default; assigned by
  `ColorNameButton` to `PixelFont.normal`)
  The text font, forwarded from `ColorNameButton`.

## Signals

This component defines no additional signals.

## Methods

This component defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

// The surface is normally driven by a ColorNameButton; used directly it
// provides the swatch + name visual in an arbitrary container.
ColorNameButtonSurface {
    width: 160
    height: 28
    color: "green"
    colorName: "green"
    highlighted: someSelection === "green"
}
```
