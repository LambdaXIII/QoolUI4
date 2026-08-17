# DragMoveArea

A drag area with incremental semantics: during a drag it emits relative
displacement deltas that can be applied to move any target.

`DragMoveArea` is a `MouseArea` subclass. While the mouse is pressed and
moved, each mouse position change emits `wannaMove(offsetX, offsetY)`
carrying the **delta relative to the previous position**. By default
(`autoBind` is `true`) the delta is automatically added to the `target`
position. With `autoBind` disabled, the consumer handles `wannaMove` itself
(for example `RectResizer` handles resize the host size from the deltas).

## Delta basis

The `wannaMove` deltas are computed in **scene coordinates** (internally via
`mapToItem(null)`). During a drag the component may itself be moved
externally (e.g. `Floater` pulls its content back to a new position, or a
window is dragged), which would pollute a local-coordinate basis (delta =
mouse displacement − component displacement, producing a stop–go–stop
jitter and losing the pointer). Scene coordinates are the mouse's true
position, decoupled from the component's own movement.

## Cooperation with system drag

An instance may override `onPressed` to use system-level dragging (e.g.
`QoolWindowBG`'s `startSystemMove`/`startSystemResize`, which falls back to
the incremental path on failure under Windows). The internal drag basis is
established through a `Connections` listening to `pressedChanged`, so it is
unaffected by signal-handler overrides.

## Properties

- `target : Item` (default `parent`)
  The item moved when `autoBind` is enabled.

- `autoBind : bool` (default `true`)
  When `true`, the drag delta is automatically added to `target`'s position.
  When `false`, only `wannaMove` is emitted and the consumer handles it
  (delta semantics as described in the overview).

- `hovered : bool` (read-only, auto-updated)
  Whether the mouse is currently hovering over the area.

Inherited from `MouseArea`: `pressed`, `mouseX`, `mouseY`,
`acceptedButtons`, `enabled`, `onEntered`, `onExited`, and all other
`MouseArea` members.

## Signals

- `wannaMove(real offsetX, real offsetY)`
  Emitted on each mouse position change while dragging, carrying the delta
  relative to the previous emitted position (scene-coordinate basis — see
  the overview).

Inherited from `MouseArea`: `pressed`, `released`, `entered`, `exited`,
`positionChanged`, `pressAndHold`, `clicked`, `doubleClicked`, and others.

## Methods

This type defines no additional methods (inherits `MouseArea` methods).

## Usage Example

```qml
import QtQuick
import Qool

DragMoveArea {
    target: targetItem          // moved automatically while dragging
    autoBind: true
    anchors.fill: targetItem
}

// Manual handling with autoBind disabled:
DragMoveArea {
    autoBind: false
    onWannaMove: (dx, dy) => { /* apply dx, dy yourself */ }
}
```
