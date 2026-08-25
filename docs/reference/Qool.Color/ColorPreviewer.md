# ColorPreviewer

A preview surface for the current color: a divided (up to four) rounded
swatch showing the color against light/dark underlays.

`ColorPreviewer` is a rounded preview item rendering the color with an
optional two-part background backdrop and an optional two-part content
split, all drawn as `ShapePath` rectangles on a `Shape`:

- **Background backdrop** (top/bottom): the whole swatch is divided
  horizontally at `verticalRatio` into a top band (`backgroundColor1`,
  default black) and a bottom band (`backgroundColor2`, default white).
- **Content split** (left/right): the color is drawn over the backdrop in
  a left portion (`solidColor` — alpha stripped, so it reads as the pure
  color) and a right portion (`color` — original, including alpha). The
  split is at `horizontalRatio`.

Diagonally this composes a 2×2 grid: the top-left quadrant is the solid
color on the top backdrop, the bottom-right the alpha color on the bottom
backdrop — so a single preview shows the color both as solid (against
dark) and as its alpha-mixed form (against light).

### Positioning

This is a *pure preview element*, not a complete widget: it only renders
the color surface and provides **no** style chrome (no border, no
foreground-contrast decoration). The host wraps it according to the
overall style — e.g. adds a frame, uses it as a Button surface, or
combines it with other primitives.

### Defaults and size

The default `colorAssistant` comes pre-configured with
`Qt.alpha(Style.highlight, 0.5)`, so standalone use works without
injection or external context. The default size is `implicitWidth: 150` /
`implicitHeight: 50`; the host may override it.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Qt.alpha(Style.highlight, 0.5)`)
  The preview data source. The preview follows it immediately via property
  binding.

- `radius : real` (default: `10`)
  The corner radius of the preview surface.

- `backgroundColor1 : color` (default: `"black"`)
  The top backdrop band color (the backdrop under the solid-color part).

- `backgroundColor2 : color` (default: `"white"`)
  The bottom backdrop band color (the backdrop under the alpha-color
  part) — demonstrate how a semi-transparent color mixes with a light
  background.

- `horizontalRatio : real` (default: `0.5`)
  The left/right split ratio of the content — the left (solid) portion
  width is `bound(radius, width * horizontalRatio, width - radius)`
  (clamped so it never collapses below the corner radius).

- `verticalRatio : real` (default: `0.5`)
  The top/bottom split ratio of the backdrop — the top band height is
  `bound(radius, height * verticalRatio, height - radius)`.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorPreviewer {
    width: 120
    height: 80
    colorAssistant: assistant
    radius: 6
}
```

As a color popup/card background with readable foreground text:

```qml
import QtQuick
import Qool.Color

Item {
    id: card
    width: 160
    height: 90

    ColorPreviewer {
        anchors.fill: parent
        colorAssistant: assistant
    }

    Text {
        anchors.centerIn: parent
        text: ColorHQ.colorName(assistant.color)
        color: assistant.recommendedForegroundColor
    }
}
```
