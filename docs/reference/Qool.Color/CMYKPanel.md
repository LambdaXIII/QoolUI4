# CMYKPanel

A CMYK color space editing panel: a single row of four vertical channel
controls for cyan, magenta, yellow and black.

`CMYKPanel` is a `GridLayout` that lays out four `ColorChannelControl`
instances in vertical orientation (a fill-bar slider on top, a mirrored
numeric edit row with the short channel tag below) in one row spanning
the available width — cyan, magenta, yellow, black in that order. Each
column writes its channel to the bound `colorAssistant` (`cyanF`,
`magentaF`, `yellowF`, `blackF`); dragging moves the value from 0
(bottom) to 1 (top), clicking the track jumps, keyboard stepping works.
A value write from any source briefly highlights the column border.

Every column embeds a numeric input following the module-wide numeric
convention (see below).

The panel does not define a default size — the host decides the width and
height, and the columns share the width equally through the grid layout.
The panel works standalone without injection because its default
`colorAssistant` instance comes pre-configured with `Style.highlight`.

### Channel input convention

Channel inputs follow the module-wide numeric convention
(`ColorNameHQ.parseChannelNumberFloat`, shared with `ColorChannelEdit`):
an entered value `x > 1` is treated as `x / 1000`, so integers from 0 to
1000 can be typed directly to express a 0..1 ratio (e.g. `350` means
0.35), and the result is clamped to `[0, 1]`. This is the inherited v3
panel behavior, not a bug — do not "fix" it into a plain division.

## Properties

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The color data source. Each column reads and writes its channel on
  this object. Inject a shared `ColorAssistant` to keep multiple panels
  synchronized on the same color.

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

CMYKPanel {
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

CMYKPanel {
    colorAssistant: shared
    Layout.fillWidth: true
    Layout.preferredHeight: 120
}
```
