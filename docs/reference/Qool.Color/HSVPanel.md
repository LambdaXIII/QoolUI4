# HSVPanel

An HSV color space editing panel: hue/saturation numeric inputs, an HSV
gradient wheel, and value/alpha sliders.

`HSVPanel` is a `ColumnLayout` composing, top to bottom:

1. A numeric input row: HUE / SATURATION channel inputs (`NumInput`).
2. An `HSVWheel` surface: a hue × saturation gradient wheel.
3. A `ColorSlider_Value` value slider.
4. A `ColorSlider_Alpha` alpha slider (visibility controlled by
   `showAlpha`).

### Interaction

- **Surface**: press-drag picks a color (hue/saturation written to
  `colorAssistant.hsvHueF` / `hsvSaturationF`; clicks outside the circle
  are clamped to the circumference); double-click resets to hue = 0,
  sat = 0 (achromatic).
- **Sliders**: drag changes the value (value/alpha); double-click resets
  to each slider's default of 1.
- **Numeric input**: click to edit, Enter or focus loss commits; a value
  `x > 1` is interpreted as `x / 1000` (see below).

### Channel input convention

Channel inputs follow the module-wide numeric convention: an entered value
`x > 1` is treated as `x / 1000`, so integers from 0 to 1000 can be typed
directly to express a 0..1 ratio (e.g. `350` means 0.35), and the result is
clamped to `[0, 1]`. This is the inherited v3 panel behavior, not a bug —
do not "fix" it into a plain division. The logic lives in
`NumInput.parseChannelValue()`.

### Defaults

The default `colorAssistant` comes pre-configured with `Style.highlight`,
so standalone use works without injection. The panel defines no default
size — the host decides the width, height and layout weights.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The color data source. Inject a shared `ColorAssistant` to keep
  multiple panels synchronized on the same color.

- `showAlpha : bool` (default: `true`)
  Whether the alpha slider is shown.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch. When false, surface/slider animations
  complete instantly.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: shared
    color: Style.highlight
}

HSVPanel {
    colorAssistant: shared
    showAlpha: false
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```
