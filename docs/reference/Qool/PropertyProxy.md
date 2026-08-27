# PropertyProxy

A stateless property proxy: bridges an arbitrary object property (named by
a string) and exposes it as a readable, writable, and reactively updating
`value`. QML bindings cannot address a property by string name, so a host
cannot connect to an arbitrary `target` + `property` at runtime;
PropertyProxy closes that gap.

`value` is a **stateless proxy**: the getter reads `target.property` live,
and the setter writes it back (when writable). There is no internal storage
and a single source of truth — hence no sync race and no "rollback" notion:
when the target is not writable, a write is ignored (with a warning) and
`value` keeps reflecting the target's true value.

Updates follow a dual path. On (re)establishing an observation, `value`
syncs once immediately — a constant property thereby reaches its final
value with no further mechanism. If the target property has a NOTIFY
signal, updates are event-driven (the notify signal re-emits
`valueChanged`). Otherwise `value` polls according to `interval`, which
defaults to no polling. The polling change snapshot is used only to compare
for change, never to serve reads or writes.

`isWritable` is **purified writability**: the meta-object is writable
(`QMetaProperty::isWritable()`) and not constant (`!isConstant()`). The
full set of meta-object capabilities — `isReadable`, `isWritable`,
`isConstant`, `isResettable`, `isBindable` — is exposed (read-only,
refreshed per observation).

When `target` is null, the property is invalid, or the property is not
readable, `value` is invalid, all capability properties are `false`, and no
update mode is entered.

## Properties

- `target : object`
  The object whose property is proxied. Setting it (re)establishes the
  observation. Destroying the target reverts the proxy to the invalid
  state.

- `property : string`
  The name of the proxied property on `target`. Setting it (re)establishes
  the observation.

- `value : var` (read/write)
  The proxied value — a live window on `target.property`. Reading returns
  the current value; writing writes back to `target.property` when writable
  (see `isWritable`), otherwise it is ignored with a warning. Invalid when
  `target` is null, the property is invalid, or the property is not
  readable.

- `interval : int` (default `-1`)
  Polling interval in milliseconds for target properties without a NOTIFY
  signal. `< 0` disables polling (the default — busy polling is opt-in);
  `0` polls every event-loop cycle; `> 0` polls at a fixed interval.
  Ignored when the target property has a NOTIFY signal (event-driven).

- `isReadable : bool` (read-only)
  Whether the proxied property is readable
  (`QMetaProperty::isReadable()`).

- `isWritable : bool` (read-only)
  Purified writability — the meta-object is writable and not constant. The
  single guard for the write direction.

- `isConstant : bool` (read-only)
  Whether the proxied property is constant
  (`QMetaProperty::isConstant()`).

- `isResettable : bool` (read-only)
  Whether the proxied property is resettable
  (`QMetaProperty::isResettable()`).

- `isBindable : bool` (read-only)
  Whether the proxied property is bindable
  (`QMetaProperty::isBindable()`).

## Signals

- `isReadableChanged()`, `isWritableChanged()`, `isConstantChanged()`,
  `isResettableChanged()`, `isBindableChanged()`
  Emitted to refresh the corresponding capability for QML bindings whenever
  the observation is (re)established — on a `target` or `property` change —
  or when the target is destroyed. Emitted unconditionally on rebuild and
  may therefore fire even when the capability value is unchanged.

## Methods

None.

## Usage Example

```qml
import QtQuick
import Qool

// A host receives a property name as a string (e.g. from data/config) and
// cannot write a compile-time binding to it — bridge it dynamically.
Item {
    id: root
    property string bridgedName: "opacity"

    PropertyProxy {
        id: proxy
        target: root
        property: bridgedName
    }

    // Read the proxied value (root.opacity through the proxy).
    readonly property real proxied: proxy.value

    // Write through the proxy (writes back to root.opacity when writable).
    TapHandler {
        onTapped: proxy.value = 0.5
    }

    // React to changes of the proxied value.
    Connections {
        target: proxy
        function onValueChanged() { /* react */ }
    }
}
```
