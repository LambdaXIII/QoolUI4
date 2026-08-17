# IndexIndicator

A dot indicator showing the current index (used as the `indicator` of
controls such as `ComboBox`).

`IndexIndicator` renders one dot per model item and highlights the dot whose
index equals `currentIndex` (default `-1`: none highlighted). `model`
provides the dot count, `currentIndex` selects the highlighted dot, and
`delegate` can replace the dot appearance wholesale — the default is a 4 × 4
dot (highlight color for the highlighted dot, normal color otherwise;
highlighted dot opaque, normal dots at 0.35 opacity).
`implicitDelegateWidth`/`implicitDelegateHeight` adjust the default dot
size; `orientation` chooses the layout direction (default `Qt.Vertical`).

**Deliberate design — single column/row laid out by `count`:** in vertical
orientation (`Qt.Vertical`) `columns` is fixed to 1 and dots flow downward
by count; in horizontal orientation (`Qt.Horizontal`) `rows` is fixed to 1
and dots flow rightward. (Previously `rows` was bound to `grid.height` and
`columns` to `grid.width`, forming a self-reference cycle — height → rows →
height — with unstable binding-loop evaluation; fixing the single
column/row also guarantees the delegate's row-height/column-width adapts, so
equal-width overlay scenarios work standalone.)

## Properties

- `currentIndex : int` (default `-1`)
  The index of the highlighted dot. `-1` highlights none.

- `implicitDelegateWidth : real` (default `4`),
  `implicitDelegateHeight : real` (default `4`)
  The default dot size (the implicit size of the default delegate).

- `delegate : Component`
  The dot component, replaceable wholesale. The default is a `Rectangle`
  with `index` (required) and `highlighted` (read-only, `index ==
  currentIndex`): `color` = `Style.highlight` when highlighted else
  `Style.buttonText`, `opacity` = 1 when highlighted else 0.35, implicit
  size from `implicitDelegateWidth`/`implicitDelegateHeight`.

- `model : var` (alias to the internal `Repeater.model`)
  The model providing the dot count.

- `orientation : int` (default `Qt.Vertical`)
  Layout direction: `Qt.Vertical` — single column, dots flow downward;
  `Qt.Horizontal` — single row, dots flow rightward.

Inherited from `T.Control`: `mirrored`, `padding` (default 6 here), and all
other `Control` members. See the Qt documentation for the inherited members.

## Signals

This type defines no additional signals (inherits all signals from
`T.Control`).

## Methods

This type defines no additional methods (inherits all methods from
`T.Control`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

// Standard usage as a ComboBox indicator.
IndexIndicator {
    model: 5
    currentIndex: 2
}

// Horizontal orientation with larger default dots.
IndexIndicator {
    orientation: Qt.Horizontal
    implicitDelegateWidth: 6
    implicitDelegateHeight: 6
    model: combo.count
    currentIndex: combo.currentIndex
}

// Replace the dot appearance wholesale.
IndexIndicator {
    model: 3
    currentIndex: 0
    delegate: Rectangle {
        required property int index
        readonly property bool highlighted: index === root.currentIndex
        width: highlighted ? 8 : 6
        height: width
        radius: width / 2
        color: highlighted ? Style.active.accent : Style.mid
    }
}
```
