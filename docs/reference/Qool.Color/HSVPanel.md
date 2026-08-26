# HSVPanel

An HSV color space editing panel: hue/saturation channel editors, an HSV
gradient wheel, and value/alpha channel controls.

`HSVPanel` is a `ColumnLayout` composing, top to bottom:

1. Two `ChannelEdit` rows: HUE / SATURATION channel editors.
2. An `HSVWheel` surface: a hue × saturation gradient wheel.
3. A `ChannelControl` value control (`channel: HSVValue`).
4. A `ChannelControl` alpha control (`channel: Alpha`, visibility
   controlled by `showAlpha`).

### Interaction

- **Surface**: press-drag picks a color (hue/saturation written to
  `colorAssistant.hsvHueF` / `hsvSaturationF` **together** (two-value
  atomic write; clicks outside the circle are clamped to the
  circumference). No double-click reset — the interaction contract is
  trimmed (hue/saturation only, like `ChannelCrystalSlider`). `value` is
  driven by the value control below, not by the surface drag; the wheel's
  dim layer follows it.
- **Channel editors/controls**: edit the numeric value or drag the slider
  to set the channel; the value is written to and read from the shared
  `colorAssistant`. On-channel synchronization and clamping live inside
  `ChannelEdit` / `ChannelControl`.

### Channel input convention

Channel values follow the module-wide normalized convention implemented
by `ColorHQ.formatChannelNumberFloat` / `parseChannelNumberFloat`: a
number is displayed as one of `'0'`, `'1'`, `'.xxx'` (three decimals, no
leading zero) or `'NaN'`. On input, the digits are cleaned and an integer
without a decimal point is treated as a pure fraction (e.g. `350` →
`.350` → 0.35 — matching the display's no-leading-zero form). This is the
module-wide convention, inherited through the channel components.

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

HSVPanel {
    colorAssistant: shared
    showAlpha: false
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```
