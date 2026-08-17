# HSLPanel

An HSL color space editing panel: saturation/lightness numeric inputs, an
HSL gradient box, and hue/alpha sliders.

`HSLPanel` is a `ColumnLayout` composing, top to bottom:

1. A numeric input row: SATURATION / LIGHTNESS channel inputs
   (`NumInput`).
2. An `HSLBox` surface: a saturation × lightness gradient box.
3. A `ColorSlider_Hue` hue slider.
4. A `ColorSlider_Alpha` alpha slider (visibility controlled by
   `showAlpha`).

### Interaction

- **Surface**: press-drag picks a color (saturation/lightness written to
  `colorAssistant.hslSaturationF` / `hslLightnessF`); double-click resets
  to sat = 1, ltn = 0.5 (the pure-color midpoint — deliberately different
  from `HSVWheel`'s reset-to-achromatic semantics, do not unify).
- **Hue slider**: drag changes the hue; double-click resets to 0.
- **Alpha slider**: drag changes the alpha; double-click resets to 1.
- **Numeric input**: click to edit, Enter or focus loss commits; a value
  `x > 1` is interpreted as `x / 1000` (see below).

### Channel input convention

Channel inputs follow the module-wide numeric convention: an entered value
`x > 1` is treated as `x / 1000`, so integers from 0 to 1000 can be typed
directly to express a 0..1 ratio (e.g. `350` means 0.35), and the result is
clamped to `[0, 1]`. This is the inherited v3 panel behavior, not a bug —
do not "fix" it into a plain division. The logic lives in
`NumInput.parseChannelValue()`.

### Domain notes (inherited v3 architecture)

- The `ColorSlider_Hue` operates on `hsvHueF`, not `hslHueF` (the
  wrap-around hue semantics are equivalent in both domains and the two
  domains are synchronized through `colorAssistant.color`); `HSLBox`
  operates in the HSL domain. Both domains coexisting is v3 as-is.
- The hue slider's handling of an invalid hue (`hsvHueF < 0`, preserving
  saturation) lives inside the slider and is not touched by this panel.

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

HSLPanel {
    colorAssistant: shared
    showAlpha: true
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```
