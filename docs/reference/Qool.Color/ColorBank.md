# ColorBank

A sparse color index container — the storage backend of `ColorBankPanel`.

`ColorBank` stores colors by integer index in a `QMap<int, QColor>`. The
storage model is **sparse**: only indexes explicitly written through
`setCellColor()` are retained — writing slot 5 does not create slots 0..4.
Indexes that were never written return `defaultColor` (default
`Qt::transparent`).

### Sparse semantics (deliberate, do not switch to a contiguous list)

Storage is "whatever was written is what exists": storing slot 5 does not
create 1..4, storing slot 20 does not allocate 0..19. Indexes have no
upper bound — any non-negative integer can be used directly.

This model deliberately differs from a fixed-length contiguous list (e.g.
`QList<QColor>` preallocated by length): a contiguous list would bind the
"panel display range" to the "storage length". This type decouples display
from storage: see `cells` below. Changing the storage to a contiguous
list with a length cap would reintroduce both a display-range boundary and
capacity waste — keep the `QMap` sparse map.

### `cells` is derived from storage, not a storage bound

`cells` (read-only) equals `max(24, highest written index + 1)` — the
minimum display range the current data requires. Writing slot 30 grows
`cells` to 31; `clear()` shrinks it back to 24. `cells` is a *consequence*
of what was written, not a cap: `ColorBankPanel.cells` (a separate,
writable property) decides how many cells the panel *draws*, and the bank
may hold indexes beyond that range without loss.

### Persistence is deliberately not built in

This type intentionally does not persist (v3's built-in `QSettings`
read/write was removed): the library does not take on storage formats,
file locations or user-data lifetimes. The host picks one of three
approaches:

1. Pre-fill before injection (restore): construct a `ColorBank`, call
   `setCellColor()` for each index to restore, then inject it into a
   panel.
2. Listen to `cellColorUpdated(n)` (save): write each change to host
   storage; combine with `validCellIndexes()` and `cellColor()` for batch
   restore on startup (the read side).
3. Subclass or re-implement: subclass this type (the protected `m_colors`
   is directly accessible) or re-implement the same interface on the host
   side with embedded persistence logic.

### `validCellIndexes` purpose

`validCellIndexes()` is the host's persistence "read side": it returns all
written indexes (ascending, no duplicates) so the host can export them in
batch (iterating `cellColor()` to write files) or reconcile against its
own index bookkeeping. Without it the host would have to maintain a
separate "which slots were written" list that can drift from the actual
data — this method keeps enumeration and data in one source.

### Equality guards (do not remove)

Every mutator carries an equality guard: when the effective color at an
index does not actually change, no signal is emitted — consistent with the
v4 signal semantics (`Changed` only fires when the value actually
changes). Consequences:

- Writing the current `defaultColor` into an unset slot (`setCellColor`)
  passes the guard early, is not stored and emits nothing.
- `setCellColors()` drops items equal to `defaultColor` on rebuild.
- `eraseCellColor()` on an unoccupied index is a silent no-op.
- `clear()` on an already-empty bank is a silent no-op.
- `cells`/`validCellIndexes` notifications fire only when their value
  actually changes.

## Properties

- `defaultColor : color` (default: `Qt::transparent`, writable)
  The color returned for indexes that were never written. Changing it
  re-emits `cellColorUpdated` for every currently-empty index (their
  effective color changed) and emits `defaultColorChanged`.

- `cells : int` (read-only, default `24`)
  `max(24, highest written index + 1)`. NOTIFY `cellsChanged` — fires only
  when the value changes: writing a new highest index grows it, `clear()`
  shrinks it, erasing a non-highest index does not change it.

- `validCellIndexes : list<int>` (read-only)
  All written indexes, ascending, without duplicates. NOTIFY
  `validCellIndexesChanged` — fires only when the written key set changes.

## Signals

- `cellColorUpdated(int index)`
  Emitted after the effective color at `index` actually changed: a
  `setCellColor()` that passed the equality guard, an `eraseCellColor()`,
  a `setCellColors()` rebuild that changed the effective color at that
  index, or a `defaultColor` change that affects an empty index.

- `defaultColorChanged()`, `cellsChanged()`, `validCellIndexesChanged()`
  Value-changed notifications for the corresponding properties.

## Methods

- `color cellColor(int index)`
  Returns the color stored at `index`, or `defaultColor` if never written.

- `void setCellColor(int index, color)`
  Sets the color at `index`. Equality guard: no-op (no signal, not
  stored) when the new value equals the current effective color —
  including writing the default color into an unset slot. `index` may be
  any non-negative integer (no upper bound); writing a new highest index
  grows `cells`.

- `void eraseCellColor(int index)`
  Removes the stored color at `index`; silent no-op when unoccupied.
  Emits `cellColorUpdated(index)`; `cells` shrinks when the removed index
  was the highest.

- `list<color> cellColors()`
  Returns the effective colors of cells `0..cells-1` (length equals
  `cells`), with `defaultColor` for unwritten indexes.

- `void setCellColors(list<color> colors)`
  Replaces the whole storage: clears the map and writes `colors` by list
  position; items equal to `defaultColor` are not stored. Emits
  `cellColorUpdated` per index whose effective color changed (over the old
  keys plus the new range), and `cells`/`validCellIndexes` notifications
  as they change. There is no truncation — the list length decides how
  many indexes are written.

- `void clear()`
  Empties the storage; silent no-op when already empty. Emits
  `cellColorUpdated` for every previously-written index, shrinks `cells`
  to 24.

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorBank {
    id: bank

    Component.onCompleted: {
        bank.setCellColor(0, "#ff0000")
        bank.setCellColor(5, "#00ff00")   // indexes 1..4 are not created
        bank.setCellColor(40, "#0000ff")  // outside any panel display range
    }
}

// Enumerate for persistence export:
// for (const n of bank.validCellIndexes()) ... bank.cellColor(n)
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
```
