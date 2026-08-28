# ActionInstantiator

Instantiates one `ClickableText` per `Action` — a `Repeater` subclass that
turns a list of `Action` objects into clickable text items.

`ActionInstantiator` inherits `Repeater` and exposes a default property
`actions` (a `list<Action>`): each declared `Action` child becomes one
delegate instance of `ClickableText` whose `action` is bound to the model
item, so the standard `Action` semantics (`text`, `checkable`/`checked`,
`enabled`, `triggered()`) work as documented by Qt. The delegate is fixed —
this type is a convenience instantiator, not a configurable view.

## Properties

- `actions : list<Action>` (default property)
  The actions to instantiate. Declared as children of this type (the
  default property) or assigned programmatically; each entry produces one
  `ClickableText` delegate with its `action` set to the entry.

Inherited from `Repeater`: `model` (bound to `actions`), `delegate` (the
fixed `ClickableText`), `count`, `itemAt()` and all other `Repeater`
members. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from
`Repeater`).

## Methods

This type defines no additional methods (inherits all methods from
`Repeater`, notably `itemAt()`).

## Usage Example

```qml
import QtQuick
import QtQuick.Controls
import Qool.Controls

ActionInstantiator {
    Action {
        text: qsTr("Select all")
        onTriggered: selectAll()
    }
    Action {
        text: qsTr("Delete")
        enabled: selection.count > 0
        onTriggered: removeSelection()
    }
}
```
