# ColorPreviewer

A preview surface for the current color: solid left half, alpha-preserving
right half.

`ColorPreviewer` is a rounded preview item showing the color in two halves:

- **Left half**: the solid color (`colorAssistant.solidColor`, alpha
  stripped).
- **Right half**: the original `color` including alpha — top on a
  transparent underlay, bottom on a white underlay — demonstrating how a
  semi-transparent color mixes with a light background (visible with the
  default instance's alpha 0.5).

### Positioning

This is a *pure preview element*, not a complete widget: it only renders
the color surface and provides **no** style chrome (no border, no
foreground-contrast decoration). The host wraps it according to the
overall style — e.g. adds a frame, uses it as a Button surface, or
combines it with other primitives.

### Defaults and size

The default `colorAssistant` comes pre-configured with
`Qt.alpha(Style.highlight, 0.5)`, so standalone use works without
injection or external context. The component defines no default size —
the host decides the width and height (e.g. `Layout.preferredHeight: 80`
in the example page, `implicitHeight: 30` as a slot background;
`ColorBankSlotButton` uses this component as its background with radius 5).
Standalone use requires explicit sizing.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Qt.alpha(Style.highlight, 0.5)`)
  The preview data source. The preview follows it immediately via property
  binding.

- `radius : real` (default: `10`)
  The corner radius of the preview surface.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorPreviewer {
    Layout.preferredWidth: 120
    Layout.preferredHeight: 80
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
        text: ColorNameHQ.name(assistant.color)
        color: assistant.recommendedForegroundColor
    }
}
```
