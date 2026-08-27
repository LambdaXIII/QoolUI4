# SmartObject

The common non-visual base type for Qool helper objects. `SmartObject` is a
plain `QObject` (no rendering) that provides two things useful to QML-based
helpers: a `parent` property with reliable change notification, and an
append-only default list property (`smartItems`) for declaring and observing
child objects.

QML type name: `SmartObject` (import `Qool`). C++ class: `qoolui::SmartObject`
(header `qool_smartobj.h`). It is used as the base of helper types such as
`ShapeControl`, `GeoLocker`, `TimerLatch`, and `CutSizesLocker`.

## Properties

- `parent : object` (read/write)
  The object's parent, exposed with change notification. Reading returns the
  current parent (`null` when none). Writing reparents the object — writing
  `null` detaches it. The write is value-guarded: no notification occurs when
  the parent is unchanged.

- `smartItems : list<object>` (read-only, default property)
  The default property: child objects declared inside a `SmartObject` in QML
  are appended to this list. The list is **append-only** — there is no removal
  or replacement API; reading yields the appended objects in insertion order
  (length/indexing work as for a JS array). Because `smartItems` is the
  default property, an explicit assignment such as `smartItems: [...]` also
  **appends** the given objects to the existing list rather than replacing it
  (`QML_LIST_PROPERTY_ASSIGN_BEHAVIOR_REPLACE_IF_NOT_DEFAULT` resolves to
  append for a default property). The property itself is `CONSTANT` — only the
  contents grow; each append is announced through `itemAppended`.

  The list holds references, not ownership: appending does not reparent the
  child, and ownership of QML-declared children follows the engine's ordinary
  rules (the `ParentProperty` class info declares `parent` as the ownership
  parent).

## Signals

- `parentChanged()`
  Emitted when the parent changes — set, cleared, or reparented — observed via
  `QEvent::ParentChange`. Additionally, when the object completes (component
  instantiation finished) and has no parent, `parentChanged` is emitted once,
  re-asserting the parentless state so that bindings on `parent` evaluated
  during instantiation are refreshed.

- `itemAppended(child : object)`
  Emitted immediately after `child` is appended to `smartItems`.

## Methods

- `dumpProperties()` (debug)
  Prints diagnostic output: the current parent, the `objectName` when set, then
  every property declared by this class and its subclasses (from the class's
  property offset to the end of the most-derived meta-object) with its index,
  name, and current value. Intended for inspection during development; has no
  effect on state.

## Extension Points (C++ subclasses)

- `appendChild(QObject *child)` (protected, virtual)
  The single append path for `smartItems` — the QML list's append function
  routes through it. The base implementation records the child in the internal
  list and emits `itemAppended`. Subclasses may override to extend or restrict
  appends; an override that keeps list membership and notification must call
  the base implementation (as `ShapeControl` does).

- `classBegin()` / `componentComplete()` (protected, overrides)
  `QQmlParserStatus` hooks. The base `classBegin` is a no-op; the base
  `componentComplete` emits `parentChanged` when the object completes without
  a parent. Overrides must call the base implementation to preserve this
  behavior.

- `bindableParent()` (public)
  Returns a `QBindable<QObject*>` for the `parent` property, enabling Qt's
  bindable-property APIs from C++.

## Usage Example

```qml
import QtQuick
import Qool

SmartObject {
    id: root

    // Child declarations become smartItems entries (default property).
    QtObject { id: marker }
    Timer { interval: 1000; repeat: true; running: true }

    onItemAppended: (child) => console.log("appended:", child)
    onParentChanged: console.log("parent is now:", root.parent)

    Component.onCompleted: {
        console.log(root.smartItems.length)   // 2
        root.dumpProperties()                 // debug inspection
    }
}
```
