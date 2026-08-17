# Floater

A simplified popup layer: the content renders under `target` (default
`Overlay`), while declared geometry lives in the parent coordinate system.

`Floater` is a simplified `Popup`: it does no modality, focus, dismiss, or
transition handling — it only guarantees "correct position". From the host's
perspective, a `Floater` is a proxy for its `content`: the content renders
under `target`, but geometry, z-order, opacity, visibility, and enabled state
are fully synchronized from this component through the proxy contract.
Observations and operations the parent applies to this component are passed
through to the content, which stays transparent and not directly operable by
the parent.

It inherits from `Item`, so the full `Item` API is available.

### Position

The content's position equals this component's top-left corner in the
`target` coordinate system (a scene-coordinate channel, independent of
window position). Any translation/scale/rotation in the ancestor chain
automatically triggers recomputation (driven by `PositionTracker`). The
content's size and opacity follow this component.

### Z-order

When multiple `Floater`s share the same `target`, the declared `z` is the
z-order within the target — the only way for the host to disambiguate
stacking order of layers sharing a target.

### Visibility and enabled

When the parent chain is explicitly hidden, Qt's flow-on automatically
applies (this component's `visible` value change propagates to the content).
Hiding/disabling along the target chain acts directly on the content's
render layer and is not reflected in this component's property values. The
content root's `visible`/`enabled` are driven by the proxy contract — the
usual way to show/hide a floating layer is to control this component's
`visible` or `opacity` (`QoolTip` uses `opacity`); use the `noVisibleSync`
switch when the content must decide for itself.

### Events

The content's hit-testing/events go through the target chain (`Overlay`),
not through the proxy — a `MouseArea` a parent stacks above this component
will not intercept the content. This is intended (decoration is not blocked
by the host).

### Switches

When `noVisibleSync` / `noEnabledSync` is enabled, the contract gives up
synchronizing the corresponding property and the content returns to Qt's
default mechanism (free to bind/set itself). Cost: the parent's operations
on this component's corresponding property no longer reach the content — if
the parent hides the `Floater` and the content does not handle it itself, it
still shows (the content can reference this component through its
declaration chain to respond).

### Other

When `content` is replaced at runtime, the old object remains under `target`
(parent not restored, geometry frozen) — the host cleans up itself. Opacity
synchronization is value synchronization: when an ancestor chain of this
component has opacity ≠ 1, the content's effective opacity may differ from
this component (value sync is the contract — intended behavior).

## Properties

- `target : Item` (default `T.Overlay.overlay`)
  The content's render parent. May be any item layer. Runtime switching
  takes effect automatically (the tracker migrates with the binding and the
  coordinates recompute).

- `content : Item`
  The floating-layer content (declared as this component's property value).
  Renders under `target`; its geometry and state properties are managed by
  the proxy contract.

- `globalPos : point` (read-only, auto-updated)
  This component's top-left corner in screen coordinates.

- `floatingPos : point` (read-only, auto-updated)
  The content's position in the `target` coordinate system.

- `noVisibleSync : bool` (default `false`)
  Disables `visible` synchronization. When enabled, the contract stops
  syncing `visible` and the content returns to Qt's default mechanism (see
  "Switches").

- `noEnabledSync : bool` (default `false`)
  Disables `enabled` synchronization. When enabled, the contract stops
  syncing `enabled` and the content returns to Qt's default mechanism (see
  "Switches").

## Signals

This type defines no additional signals. Property changes are notified
through Qt's automatically generated `xxxChanged` signals (e.g.
`noVisibleSyncChanged`, `noEnabledSyncChanged`); it inherits all `Item`
signals.

## Methods

This type defines no additional methods (inherits all `Item` methods).

## Usage Example

```qml
import QtQuick
import QtQuick.Templates as T
import Qool

Floater {
    id: floater
    // default target: T.Overlay.overlay
    content: Rectangle {
        width: 200
        height: 100
        color: Style.controlBackgroundColor
        Text { anchors.centerIn: parent; text: "floating" }
    }
    visible: showFloater  // controlling the proxy hides/shows the content
}
```
