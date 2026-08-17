# RGBPanel

An RGB color space editing panel: a single row of vertical channel sliders
for brightness, red, green, blue and alpha.

`RGBPanel` is a `GridLayout` that lays out vertical channel sliders in one
row spanning the available width:

- `ChannelSlider_Brightness` — the brightness channel (visibility
  controlled by `showBrightness`, hidden by default).
- `ChannelSlider_Red` / `ChannelSlider_Green` / `ChannelSlider_Blue` —
  the three primary channels.
- `ChannelSlider_Alpha` — the alpha channel (visibility controlled by
  `showAlpha`).

### Interaction

- Each slider writes its channel to the bound `colorAssistant` —
  `redF`/`greenF`/`blueF`/`alphaF` (the brightness slider uses
  `hsvValueF`); dragging moves the value from 0 (bottom) to 1 (top),
  double-clicking resets the channel to its default value of 1 (full
  channel).
- Every slider embeds a numeric input: clicking enters edit mode, and a
  value `x > 1` is interpreted as `x / 1000` and clamped to `[0, 1]`
  (see below).

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
size — the host decides the width and height, and the sliders share the
width equally through the grid layout.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The color data source. Each slider reads and writes its channel on this
  object. Inject a shared `ColorAssistant` to keep multiple panels
  synchronized on the same color.

- `showAlpha : bool` (default: `true`)
  Whether the alpha channel slider is shown.

- `showBrightness : bool` (default: `false`)
  Whether the brightness channel slider is shown (hidden by default,
  matching v3).

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch. Note that this panel does not forward the
  property to its sliders (each slider reads `Style.animationEnabled`
  itself, matching v3); here it exists as API surface only.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

RGBPanel {
    showBrightness: true
    Layout.fillWidth: true
    Layout.preferredHeight: 120
}
```

Inject a shared assistant to synchronize several panels:

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: shared
    color: Style.highlight
}

RGBPanel {
    colorAssistant: shared
    Layout.fillWidth: true
    Layout.preferredHeight: 120
}
```
