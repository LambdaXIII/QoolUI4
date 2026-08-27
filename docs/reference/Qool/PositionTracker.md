# PositionTracker

A 2D position tracker: tracks the scene and screen coordinates of a local
`point` on a `target`.

Given a `target` (`QQuickItem`) and a `point` (a `target`-local coordinate,
default the origin), `PositionTracker` listens layer by layer to the target's
ancestor chain for coordinate/transform/topology changes and maintains the
point's `scenePos` (scene coordinates), `globalPos` (screen coordinates) and
`currentWindow` (the containing scene).

Any translation/scale/rotation in the ancestor chain automatically triggers
recomputation; coordinate-change notifications are merged per event-loop
batch (a zero-timer, so the delay is at most one frame — multiple changes
within one batch collapse into a single recompute) and values that did not
change are not re-notified. Topology changes (reparenting, window, `target`)
rebuild the listener chain immediately, while the recomputation itself is
deferred to the batch flush. The initial recompute is scheduled for the first
event-loop batch, so `target`/`point` assigned later (e.g. from QML) trigger
the computation again and the output converges.

When `target` is not set explicitly it defaults to the parent item at
construction time (a snapshot: a later change of the QObject parent does not
retarget); when `target` is `null` the tracker has no coordinate system to
map, so `scenePos` and `globalPos` both equal `point` and `currentWindow` is
`null` — the passthrough keeps the semantics continuous, and absence of a
window is expressed by `currentWindow` being `null` (`(0, 0)` remains a legal
coordinate); when the target has no window, `globalPos` equals `scenePos`.

Unlike `ItemTracker`, coordinates have no flow-on, so the ancestor chain must
be listened to layer by layer — listening to the target's own signals would
not cover ancestor translations.

## Properties

- `target : QQuickItem`
  The item to track. Defaults to the parent item at construction time (a
  snapshot — a later change of the QObject parent does not retarget); if the
  construction-time parent is not a `QQuickItem`, the default is `null`.
  Setting it to `null` makes the tracker pass `point` through unchanged.

- `point : point`
  A `target`-local coordinate (default `(0, 0)`). Its scene/screen
  coordinates are tracked.

- `scenePos : point` (read-only)
  The tracked point in scene coordinates. Independent of window position.

- `globalPos : point` (read-only)
  The tracked point in screen coordinates. Equals `scenePos` when the target
  has no window. In a `QQuickWidget` mixed scene, `currentWindow` is the
  internal offscreen render window (not the display container), so
  `globalPos` does not reflect the real screen position — `scenePos` is
  unaffected.

- `currentWindow : QQuickWindow` (read-only)
  The scene window the tracked point belongs to, or `null` when the target
  has no window.

## Signals

All properties notify through Qt's automatically generated `xxxChanged`
signals (value-guarded: emitted only when the actual value changes).
`scenePosChanged` / `globalPosChanged` / `currentWindowChanged` are
position-update notifications — after a forced recompute (`update()`), a
value change is notified through them too; `targetChanged` / `pointChanged`
are configuration-change notifications.

## Methods

- `update()`
  Forces an immediate recompute and notification (the synchronous entry for
  batch merging: geometry changes are normally deferred to the event-loop
  batch flush; this method skips the delay and runs immediately). If a batch
  was already scheduled, the later flush callback no-ops because the dirty
  flag is cleared.

## Usage Example

```qml
import QtQuick
import Qool

PositionTracker {
    id: tracker
    target: trackedItem
    point: Qt.point(0, 0)

    // onScenePosChanged / onGlobalPosChanged fire when the tracked
    // point's coordinates change (value-guarded).
}
```
