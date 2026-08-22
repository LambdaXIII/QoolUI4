# HSLPanel

An HSL color space editing panel: saturation/lightness channel editors, an
HSL gradient box, and hue/alpha channel controls.

`HSLPanel` is a `ColumnLayout` composing, top to bottom:

1. Two `ColorChannelEdit` rows: SATURATION / LIGHTNESS channel editors.
2. An `HSLBox` surface: a saturation × lightness gradient box.
3. A `ColorChannelControl` hue control (`channel: HSVHue`).
4. A `ColorChannelControl` alpha control (`channel: Alpha`, visibility
   controlled by `showAlpha`).

### Interaction

- **Surface**: press-drag picks a color (saturation/lightness written to
  `colorAssistant.hslSaturationF` / `hslLightnessF`); double-click resets
  to sat = 1, ltn = 0.5 (the pure-color midpoint — deliberately different
  from `HSVWheel`'s reset-to-achromatic semantics, do not unify).
- **Channel editors/controls**: edit the numeric value or drag the slider
  to set the channel; the value is written to and read from the shared
  `colorAssistant`. On-channel synchronization and clamping live inside
  `ColorChannelEdit` / `ColorChannelControl`.

### Channel input convention

Channel values follow the module-wide normalized convention implemented
by `ColorNameHQ.formatChannelNumberFloat` / `parseChannelNumberFloat`: a
number is displayed as one of `'0'`, `'1'`, `'.xxx'` (three decimals, no
leading zero) or `'NaN'`. On input, the digits are cleaned and an integer
without a decimal point is treated as a pure fraction (e.g. `350` →
`.350` → 0.35 — matching the display's no-leading-zero form). This is the
module-wide convention, inherited through the channel components.

### Domain notes (inherited v3 architecture)

- The hue control operates on `hsvHueF` (`channel: HSVHue`), not
  `hslHueF` (the hue semantics are equivalent in both domains and the two
  domains are synchronized through `colorAssistant.color`); `HSLBox`
  operates in the HSL domain. Both domains coexisting is v3 as-is.
- The hue slider's handling of an invalid hue (`hsvHueF < 0`, preserving
  saturation) lives inside `ColorChannelSlider` (the sat-bump path) and
  is not touched by this panel.

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
  Whether the alpha control is shown.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch. When false, surface/control animations
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
