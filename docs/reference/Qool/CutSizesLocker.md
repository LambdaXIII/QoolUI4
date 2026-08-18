# CutSizesLocker

A `QoolBoxSettings`-specific plugin that locks the four corner cuts
(`cutSizeTL`/`cutSizeTR`/`cutSizeBL`/`cutSizeBR`) to one value while it is active,
and restores the previous four values when it is deactivated.

The locker does not require any cooperation from the original `QoolBoxSettings`
consumer (`QoolBox`, and so on). Installing it as a child of a `QoolBoxSettings`
attaches the target automatically; a host can also assign `target` explicitly.

## Snapshot semantics

A snapshot is taken at the moment the locker enters the locked state — that is, when
`enabled` is `true` and `target` is valid:

- `enabled` changes from `false` to `true` (target already valid) → the current four
  corner values are snapshotted.
- `target` changes while `enabled` is `true` → the old target is restored to its
  snapshot, then the new target is snapshotted and unified immediately.

Restoring happens when the locker leaves the locked state:

- `enabled` changes from `true` to `false` → the current target is restored to the
  snapshot, and the snapshot is cleared.
- `target` changes while `enabled` is `true` → the old target is restored (symmetric
  with disabling, leaving no side effects).

While the locker is active, any change among the five paths — the locker's `cutSize`
and the target's four corner properties — unifies all four corners to the current
`cutSize`.

## Properties

- `enabled` (`bool`): the locking switch. Default `true`. When `false`, target
  corners are not modified and may be edited freely.
- `cutSize` (`real`): the value all four corners are unified to while active. Default
  `0`.
- `target` (`QoolBoxSettings*`): the settings object being locked. The constructor
  attaches it automatically when the parent is a `QoolBoxSettings`; it is `null`
  otherwise, in which case the locker is a safe no-op.

## Signals

This type defines no additional signals beyond the auto-generated `xxxChanged`
signals for its properties.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

QoolBox {
    settings: QoolBoxSettings {
        CutSizesLocker {
            cutSize: 12
        }
    }

    // Or with an explicit target:
    //
    // CutSizesLocker {
    //     target: settings
    //     cutSize: 12
    // }
}
```
