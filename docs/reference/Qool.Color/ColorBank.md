# ColorBank

An unbounded sparse color index container — the storage backend of
`ColorBankPanel`.

`ColorBank` stores colors by integer index (slot number). The storage
model is **unbounded and sparse**: only indexes explicitly written through
`setColor()` are retained — writing slot 5 does not create slots 0..4
(implemented as a `QHash<int, QColor>`). Indexes that were never set are
returned by `color()` as default white (`Qt::white`).

### Sparse semantics (deliberate, do not switch to a contiguous list)

Storage is "whatever was written is what exists": storing slot 5 does not
create 1..4, storing slot 20 does not allocate 0..19. Indexes have no
upper bound — there is no "maximum slot count"; any non-negative integer
can be used directly.

This model deliberately differs from a fixed-length contiguous list (e.g.
`QList<QColor>` preallocated by length): a contiguous list would bind the
"panel display range" to the "storage length" — showing 24 cells would
mean storing at most 24, with placeholder values for every displayed cell.
This type fully decouples display (the panel's `slots` property) from
storage (the unbounded sparse map): the display range only decides how
many cells the panel draws, not how many can be stored. Changing the
storage to a contiguous list with a length cap would reintroduce both a
display-range boundary and capacity waste — keep the `QHash` sparse map.

### `slots` is a display range, not a storage bound

`ColorBankPanel`'s `slots` property (default 24) only decides which cells
are displayed (0..slots-1). Indexes beyond the display range can still be
written, read and enumerated; writing slot 20 (inside the range at
slots=24) and slot 40 (outside it) behave identically. Values outside the
range are merely "not shown", not "lost" — shrinking `slots` and enlarging
it again loses nothing.

### Persistence is deliberately not built in

This type intentionally does not persist (v3's built-in `QSettings`
read/write was removed): the library does not take on storage formats,
file locations or user-data lifetimes. The host picks one of three
approaches:

1. Pre-fill before injection (restore): construct a `ColorBank`, call
   `setColor()` for each slot to restore, then inject it into a panel.
2. Listen to `colorChanged` (save): connect `colorChanged(n)` and write
   each change to host storage; combine with `filledIndexes()` and
   `color()` for batch restore on startup (the read side).
3. Subclass or re-implement: subclass this type (the protected `m_colors`
   is directly accessible) or re-implement the same interface on the host
   side with embedded persistence logic.

### `filledIndexes` purpose

`filledIndexes()` is the host's persistence "read side": it returns all
set indexes (ascending, no duplicates) so the host can export them in
batch (iterating `color()` to write files) or reconcile against its own
index bookkeeping. Without it the host would have to maintain a separate
"which slots were written" list that can drift from the actual data —
this method keeps enumeration and data in one source.

### Equality guard

`setColor()` carries an equality guard: when the new value equals the
current one (all `QColor` channels equal), nothing is written and
`colorChanged` is not emitted — consistent with the v4 signal semantics
(`Changed` only fires when the value actually changes). A consequence:
explicitly writing default white into an unset slot does not trigger the
signal (the value did not change).

## Properties

This type defines no properties.

## Signals

- `colorChanged(int n)`
  Emitted after the color at index `n` actually changed (i.e. passed the
  `setColor()` equality guard). Writing the same value — including
  writing white into an unset slot — does not emit.

## Methods

- `color color(int n)`
  Returns the color stored at index `n`, or default white (`Qt::white`)
  if never set. The default-white return is deliberate: unsaved panel
  cells show white without host-provided placeholders. Note that "unset"
  and "explicitly set to white" are indistinguishable by this return
  value — use `filledIndexes()` when the distinction matters.

- `void setColor(int n, color)`
  Sets the color at index `n`. Carries the equality guard above. `n` may
  be any non-negative integer (no upper bound); writing an index beyond
  the already-set range does not create intermediate indexes (sparse, see
  the type overview).

- `list<int> filledIndexes()`
  Returns all set indexes, ascending, without duplicates. Returns an empty
  list when nothing has been set.

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorBank {
    id: bank

    Component.onCompleted: {
        bank.setColor(0, "#ff0000")
        bank.setColor(5, "#00ff00")   // slots 1..4 are not created
        bank.setColor(40, "#0000ff")  // outside any display range
    }
}

// Enumerate for persistence export:
// for (const n of bank.filledIndexes()) ... bank.color(n)
```
