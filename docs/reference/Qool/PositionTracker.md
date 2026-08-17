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
batch (delayed at most one frame) and values that did not change are not
re-notified. When `target` is not set explicitly it defaults to the declared
parent; when `target` is `null` the output passes `point` through unchanged;
when the target has no window, `globalPos` equals `scenePos`.

Unlike `ItemTracker`, coordinates have no flow-on, so the ancestor chain must
be listened to layer by layer — listening to the target's own signals would
not cover ancestor translations.

## Properties

- `target : QQuickItem`
  The item to track. Defaults to the declared parent when unset; setting it
  to `null` outputs `point` unchanged.

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
