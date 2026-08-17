# ItemTracker

Tracks the effective enabled state and window activation state of the item
owning a given target object.

Given an arbitrary `target` object, `ItemTracker` walks up to find the item
(`QQuickItem`) and window it belongs to, then exposes `itemEnabled`
(effective enabled — including the ancestor chain) and `windowActived`
(window active; treated as `true` when the target is not attached to a
window). Typical use: `Style` selects an appearance group
(Active/Inactive/Disabled) according to the host state.

`target` may be any `QObject` (e.g. an internal object of a control); the
tracking chain rebuilds automatically as the item/window changes.

The `itemEnabled` tracking only listens to the item's own `enabledChanged` —
`enabled` has flow-on, so any ancestor-chain change necessarily reflects in
the item's own property value (no need to listen per ancestor).

## Properties

- `target : QObject`
  The object to track. The tracker finds the owning item and window.

- `item : QQuickItem` (read-only)
  The item owning `target` (found via ancestor search), or `null` when the
  target has no item parent.

- `window : QWindow` (read-only)
  The window the item is attached to, or `null` when none.

- `itemEnabled : bool` (read-only, default `true`)
  Effective enabled state (`isEnabled`, the conjunction over the ancestor
  chain). `true` when there is no item (an untracked state is treated as
  normal, not disabled).

- `windowActived : bool` (read-only, default `true`)
  Whether the window is active. `true` when there is no window (not attached
  to a window is not treated as inactive).

## Signals

All properties notify through Qt's automatically generated `xxxChanged`
signals (value-guarded: emitted only when the actual value changes).
`itemEnabledChanged` / `windowActivedChanged` are state-output
notifications; `targetChanged` / `itemChanged` / `windowChanged` are
chain-change notifications.

## Methods

This type defines no additional public methods.

## Usage Example

```qml
import QtQuick
import Qool

ItemTracker {
    id: tracker
    target: someControl

    // Select an appearance group from the host state.
    // onItemEnabledChanged / onWindowActivedChanged fire on state change.
}
```
