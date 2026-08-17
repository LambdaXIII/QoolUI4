# ColorAssistant

A multi-color-space color object: writing any component in any space
synchronizes all spaces.

`ColorAssistant` holds a single color and exposes RGB / CMYK / HSV / HSL
component properties (in both `int` and float dual tracks) plus list
properties. Writing any component recomputes all spaces and broadcasts
all `Changed` signals.

### Dual-track components

The `int` and float (`F`-suffixed) tracks run in parallel, are
semantically identical and stay in sync: the float versions are 0..1
normalized (`redF` and friends), the `int` versions are 0..255 (`red`,
`hsvValue`, …) with hue in 0..359 (`hsvHue`, `hslHue`). The float track
serves continuous interaction (panel sliders, gradients); the `int` track
is part of the public API surface. Neither is redundant — writing either
track goes through the unified `color` setter, which recomputes every
space.

### Derived read-only properties

`solidColor` (alpha stripped), `visualBrightness` (0.299/0.587/0.114
weighted luminance) and `recommendedForegroundColor` (black/white contrast
foreground at the 0.5 luminance threshold) update with `color`. The
luminance formula matches `ThemeHQ`; because v4 C++ classes are not
dynamically exported and QML exposure goes through the type system, the
derived values are implemented internally rather than delegated across
modules.

### Change semantics

Every setter carries an equality guard: if the new value equals the
current one, nothing is broadcast. `Changed` is emitted only when the
value actually changes. The `color` setter is the single entry point —
all component/list/`name` writes funnel through it and recompute the whole
color space.

## Properties

- `color : color` (NOTIFY `colorChanged`)
  The single color held by the object. All other properties are derived
  views of this value.

- `rgbaF : list<real>`, `cmykF : list<real>`, `hsvF : list<real>`, `hslF :
  list<real>` (NOTIFY `rgbaFChanged`/`cmykFChanged`/`hsvFChanged`/`hslFChanged`)
  Float track list views: `[r, g, b, a]`, `[c, m, y, k]`, `[h, s, v]`,
  `[h, s, l]`, all 0..1. Writing a list rebuilds the color from its
  space, using the current components as defaults for missing entries.

- `rgba : list<int>`, `cmyk : list<int>`, `hsv : list<int>`, `hsl :
  list<int>` (NOTIFY `rgbaChanged`/`cmykChanged`/`hsvChanged`/`hslChanged`)
  Integer track list views with the same layout semantics, in 0..255
  (hue 0..359).

- `name : string` (NOTIFY `nameChanged`)
  The color as a string, dynamically generated: `#AARRGGBB` when the
  alpha is below 1, otherwise `#RRGGBB`. Writing parses the string via
  `QColor::fromString`.

- `solidColor : color` (read-only, NOTIFY `colorChanged`)
  The color with alpha forced to 1.

- `visualBrightness : real` (read-only, NOTIFY `colorChanged`)
  The perceived luminance, `0.299 * r + 0.587 * g + 0.114 * b` over the
  RGB channels.

- `recommendedForegroundColor : color` (read-only, NOTIFY `colorChanged`)
  The contrast foreground: black when `visualBrightness >= 0.5`, white
  otherwise.

- Float components, 0..1 (each NOTIFYs its own `xxxChanged`):
  `redF`, `greenF`, `blueF`, `alphaF`, `cyanF`, `magentaF`, `yellowF`,
  `blackF`, `hsvHueF`, `hsvSaturationF`, `hsvValueF`, `hslHueF`,
  `hslSaturationF`, `hslLightnessF`.

- Integer components (each NOTIFYs its own `xxxChanged`):
  `red`, `green`, `blue`, `alpha`, `cyan`, `magenta`, `yellow`, `black`
  (0..255); `hsvHue`, `hslHue` (0..359); `hsvSaturation`, `hsvValue`,
  `hslSaturation`, `hslLightness` (0..255).

## Signals

- `colorChanged()`
  Emitted when the color actually changes (after the full-space
  recomputation). Also serves as the NOTIFY for the derived read-only
  properties.

- `rgbaFChanged()`, `cmykFChanged()`, `hsvFChanged()`, `hslFChanged()`,
  `rgbaChanged()`, `cmykChanged()`, `hsvChanged()`, `hslChanged()`,
  `nameChanged()`
  Emitted together with `colorChanged` whenever the underlying color
  changes.

- `redFChanged()`, `greenFChanged()`, `blueFChanged()`, `alphaFChanged()`,
  `redChanged()`, `greenChanged()`, `blueChanged()`, `alphaChanged()`,
  `cyanFChanged()`, `magentaFChanged()`, `yellowFChanged()`,
  `blackFChanged()`, `cyanChanged()`, `magentaChanged()`,
  `yellowChanged()`, `blackChanged()`, `hsvHueFChanged()`,
  `hsvSaturationFChanged()`, `hsvValueFChanged()`, `hsvHueChanged()`,
  `hsvSaturationChanged()`, `hsvValueChanged()`, `hslHueFChanged()`,
  `hslSaturationFChanged()`, `hslLightnessFChanged()`, `hslHueChanged()`,
  `hslSaturationChanged()`, `hslLightnessChanged()`
  Per-component NOTIFY signals; emitted (with `colorChanged`) when the
  recomputed component actually differs from its previous value.

## Methods

- `static string hex(int number)`
  Returns the integer as a lowercase hexadecimal string; the `#` prefix is
  left to the caller.

- `static bool isValidName(string name)`
  Returns whether the string is a valid color name (CSS color name or
  `#RRGGBB` / `#AARRGGBB` form), via `QColor::isValidColorName`.

- `bool isValid()`
  Returns whether the current color is valid (false before a valid color
  has been set).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: assistant
    color: Style.highlight
}

// One shared assistant keeps every panel synchronized.
RGBPanel  { colorAssistant: assistant }
CMYKPanel { colorAssistant: assistant }

// Component access: the int and float tracks stay in sync.
Text {
    text: assistant.name
    color: assistant.recommendedForegroundColor
}

// List-style access and hex conversion.
Text {
    text: "0x" + ColorAssistant.hex(assistant.red)
}
```
