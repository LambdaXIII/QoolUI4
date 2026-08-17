# ColorBankPanel

A color bank panel: a grid of color slots with load/save interaction backed
by a `ColorBank`.

`ColorBankPanel` displays `slots` color slots (`ColorBankSlotButton`
instances) in a 6-column grid. Slot data comes from the `colorBank`
backend, and the current color is provided by `colorAssistant`. Each slot
is split into an L (load) and an S (save) area:

- **S (save)**: writes the current color into the slot —
  `colorBank.setColor(n, colorAssistant.color)`.
- **L (load)**: writes the slot color back into the current color —
  `colorAssistant.color = slotColor`.
- A slot is only clickable when its color differs from the current color
  (`loadEnabled`/`saveEnabled`); acting on an identical color would be a
  no-op. The slot number fades out on hover, the L/S areas fade in, and a
  pressed slot is highlighted by the foreground color.

### `colorBank`: own instance by default, injectable

The default `colorBank` is an in-memory `ColorBank` owned by the panel —
standalone use works with no external preparation. The host can inject its
own instance (`colorBank: myBank`) to share data:

- Injecting the same instance into several panels makes their data
  interoperate (a change in one is visible everywhere).
- Before injection the host can pre-fill the bank with
  `setColor()` (e.g. to restore persisted data); the panel then shows the
  restored data.

### `ColorBank` sparse semantics

`ColorBank` is an unbounded *sparse* index container: it only retains
slots that were explicitly written (storing slot 5 does not create slots
1..4). `slots` is purely a *display range* — the panel draws cells
0..slots-1; slots beyond the range can still be written, read and
enumerated without loss (shrinking `slots` and enlarging it again does not
lose data). "Showing 24 cells" is not "storing at most 24".

### Persistence is deliberately not built in

`ColorBank` intentionally does not persist (the v3 `QSettings` mechanism
was removed). The host picks one of three approaches:

1. Pre-fill before injection (restore): construct a `ColorBank`, call
   `setColor()` for each slot to restore, then inject it.
2. Listen to `colorChanged(n)` to record (save): write each change to host
   storage; use `filledIndexes()` and `color()` for batch restore on
   startup (the read side).
3. Subclass or re-implement: subclass `ColorBank` (the protected
   `m_colors`) or re-implement the same interface on the host side with
   embedded persistence logic.

## Properties

- `colorBank : ColorBank` (default: own in-memory instance)
  The slot storage backend. Inject a host instance to share data.

- `colorAssistant : ColorAssistant` (default: own instance with `color:
  Style.highlight`)
  The current color source. The L area writes back to this property, the S
  area reads it for saving.

- `slots : int` (default: `24`, i.e. 6 columns × 4 rows)
  The number of slots displayed. This is only the display range, not a
  storage bound (see above); changing it immediately changes the grid size.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch; forwarded to the slot buttons.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorBankPanel {
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```

Share one bank across two panels and pre-fill it:

```qml
import QtQuick
import Qool
import Qool.Color

ColorBank {
    id: bank
}

ColorBankPanel {
    colorBank: bank
    Layout.fillWidth: true
}

ColorBankPanel {
    colorBank: bank
    slots: 12
    colorAssistant: ColorAssistant { color: Style.highlight }
}
```
