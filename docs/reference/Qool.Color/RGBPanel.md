# RGBPanel

An RGB color space editing panel: a single row of vertical channel
controls for brightness, red, green, blue and alpha.

`RGBPanel` is a `GridLayout` that lays out five `ColorChannelControl`
instances in vertical orientation (a fill-bar slider on top, a numeric
edit row with the short channel tag below, `tagOnTop` stacking) in one
row spanning the available width:

- brightness (`HSVValue`, short tag `BRIT`) — visibility controlled by
  `showBrightness`, hidden by default;
- red / green / blue — the three primary channels;
- alpha — visibility controlled by `showAlpha`.

### Interaction

- Each column writes its channel to the bound `colorAssistant` —
  `redF`/`greenF`/`blueF`/`alphaF` (the brightness column uses
  `hsvValueF`). Dragging moves the value from 0 (bottom) to 1 (top);
  clicking the track jumps; keyboard stepping works. A value write from
  any source (drag, numeric edit, external change) briefly highlights
  the column border.
- Every column embeds a numeric input: clicking enters edit mode with
  the module-wide numeric convention (see below).

### Channel input convention

Channel inputs follow the module-wide numeric convention
(`ColorHQ.parseChannelNumberFloat`, shared with `ColorChannelEdit`):
an entered value `x > 1` is treated as `x / 1000`, so integers from 0 to
1000 can be typed directly to express a 0..1 ratio (e.g. `350` means
0.35), and the result is clamped to `[0, 1]`. This is the inherited v3
panel behavior, not a bug — do not "fix" it into a plain division.

### Defaults

The default `colorAssistant` comes pre-configured with `Style.highlight`,
so standalone use works without injection. The panel defines no default
size — the host decides the width and height, and the columns share the
width equally through the grid layout.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The color data source. Each column reads and writes its channel on
  this object. Inject a shared `ColorAssistant` to keep multiple panels
  synchronized on the same color.

- `showAlpha : bool` (default: `true`)
  Whether the alpha channel column is shown.

- `showBrightness : bool` (default: `false`)
  Whether the brightness channel column is shown (hidden by default,
  matching v3).

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch. Note that this panel does not forward the
  property to its columns (each column picks it up through the parent
  chain, matching v3); here it exists as API surface only.

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
