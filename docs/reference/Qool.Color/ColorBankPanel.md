# ColorBankPanel

A color bank panel: a grid of color cells with save/load interaction
backed by a `ColorBank`.

`ColorBankPanel` displays `cells` color cells in a 6-column grid. Each
cell is a `ColorPreviewer` split into an L (load) and an S (save) area,
each an `AbstractButton`:

- **S (save)**: writes the panel's current color into the bank —
  `colorBank.setCellColor(index, root.color)`.
- **L (load)**: writes the cell color back into the panel's current
  color — `root.color = cellColor`.
- A cell is only clickable when its color differs from the current color
  (`enabled: root.color !== cellColor`); acting on an identical color
  would be a no-op. The S/L labels fade in on hover, colored by
  `ThemeHQ.recommendForeground(cellColor)`; a pressed cell is highlighted
  accordingly.

Cell colors are refreshed via the bank's `cellColorUpdated` (a
`Connections` on the bank), so cells stay in sync when the bank is
mutated elsewhere (e.g. by another panel sharing the same instance).

### `colorBank`: own instance by default, injectable

The default `colorBank` is an in-memory `ColorBank` owned by the panel —
standalone use works with no external preparation. The host can inject
its own instance (`colorBank: myBank`) to share data:

- Injecting the same instance into several panels makes their data
  interoperate (a change in one is visible everywhere).
- Before injection the host can pre-fill the bank with `setCellColor()`
  (e.g. to restore persisted data); the panel then shows the restored
  data.

### `ColorBank` sparse semantics

`ColorBank` is a *sparse* index container: it only retains indexes that
were explicitly written (storing slot 5 does not create slots 1..4), and
unwritten indexes return `defaultColor` (default transparent). The
panel's `cells` only decides how many cells are *drawn* (0..cells-1); the
bank may hold indexes beyond that range without loss — "showing 24 cells"
is not "storing at most 24".

### Persistence is deliberately not built in

`ColorBank` intentionally does not persist (the v3 `QSettings` mechanism
was removed). The host picks one of three approaches:

1. Pre-fill before injection (restore): construct a `ColorBank`, call
   `setCellColor()` for each index to restore, then inject it.
2. Listen to `cellColorUpdated(n)` to record (save): write each change to
   host storage; use `validCellIndexes()` and `cellColor()` for batch
   restore on startup (the read side).
3. Subclass or re-implement: subclass `ColorBank` (the protected
   `m_colors`) or re-implement the same interface on the host side with
   embedded persistence logic.

## Properties

- `cells : int` (default: `24`, i.e. 6 columns × 4 rows)
  The number of cells displayed. This is a display range only, not a
  storage bound (see above); changing it immediately changes the grid
  size.

- `colorBank : ColorBank` (default: own in-memory instance)
  The cell storage backend. Inject a host instance to share data.

- `color : color` (default: `"transparent"`)
  The panel's current color. The S area reads it for saving, the L area
  writes the cell color back into it. Bind or sync this property to share
  the current color with the rest of the UI (see the usage example).

Animation gating is not a declared property — the cell visuals read the
`Style.animationEnabled` attached property directly.

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
    cells: 12
    color: Style.highlight
}
```

Host persistence (matching `QoolUIExample/pages/Page_Color.qml`):

```qml
Settings {
    id: colorBankSettings
}

ColorBank {
    id: colorBank
    Component.onCompleted: {
        for (let i = 0; i < 24; i++) {
            let color = colorBankSettings.value(i);
            if (color)
                colorBank.setCellColor(i, color);
        }
    }
    onCellColorUpdated: i => {
        colorBankSettings.setValue(i, colorBank.cellColor(i));
    }
}

ColorBankPanel {
    colorBank: colorBank
    // 与外部当前色联动（对齐 Page_Color 的 PropertySync 接线）：
    // PropertySync { target1: mainColor; property1: "color"; target2: parent; property2: "color" }
}
```
