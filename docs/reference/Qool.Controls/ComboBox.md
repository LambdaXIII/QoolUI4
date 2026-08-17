# ComboBox

A drop-down selection box based on `QtQuick.Templates.ComboBox`, with an
editable-text field and a configurable popup direction.

`ComboBox` combines a button and a popup list to select one item from a
model. It inherits `T.ComboBox`, so the interface is fully compatible with
`QtQuick.Controls.ComboBox` — `model`, `currentIndex`, `currentText`,
`editable`, `editText`, `accepted()`, `find()`, `validator` and the other
official APIs all work as documented by Qt. On top of the official interface
it adds appearance customization (`backgroundSettings`, `title`, `label`),
content padding (`contentPadding` family) and popup direction control
(`popupDirection`).

The popup's `delegate` defaults to `BasicItemDelegate` and follows the
control's style explicitly via `Style.follow`; hosts may replace `delegate`
to customize the item appearance.

## Properties

- `title : string` (alias to the background box's `title`)
  Title text, forwarded to the top of the background box.

- `label : string` (alias to the background box's `label`)
  Label text, forwarded to the inside of the background box.

- `contentPadding : real` (default `0`)
  Uniform padding for all four edges of the content area.

- `contentTopPadding`, `contentBottomPadding`, `contentLeftPadding`,
  `contentRightPadding : real` (default `0`)
  Per-edge content padding; each overrides the corresponding edge of
  `contentPadding`.

- `horizontalAlignment : int` (default `Text.AlignHCenter`)
  Horizontal alignment of the displayed text.

- `verticalAlignment : int` (default `Text.AlignVCenter`)
  Vertical alignment of the displayed text.

- `popupDirection : int` (default `Qore.Covered`)
  Popup placement direction: `Qore.Covered` (default) covers the control;
  `Qore.Below` puts the popup's top edge right below the control's bottom
  edge; `Qore.Above` puts the popup's bottom edge right above the control's
  top edge.

- `popupOffsetX`, `popupOffsetY : real` (default `0`)
  Extra pixel offsets of the popup relative to its default position.

- `backgroundSettings : QoolBoxSettings`
  Background appearance (border width/color, fill color, corner cuts).
  Defaults to the `Style` control look (`controlBorderWidth`,
  `controlBorderColor`, `controlBackgroundColor`, `buttonCutSize`).
  The background box is transparent (`opacity` 0) while `flat` and not
  hovered, the popup is closed and the text field is not editing.

- `rejected` — see Signals.

Inherited from `T.ComboBox`: `model`, `currentIndex`, `currentText`,
`highlightedIndex`, `editable`, `editText`, `accepted()`, `find()`,
`validator`, `textRole`, `selectTextByMouse`, `delegate`, `popup`,
`flat`/`down`/`hovered` state, and all other `ComboBox`/`Control` members.
See the Qt documentation for the inherited members. `font.pixelSize`
defaults to `Style.controlTextSize`.

## Signals

- `accepted()`
  Inherited from the official interface: emitted when an edit is accepted in
  editable mode (the input passes validation and differs from the current
  text). Handle the committed text in `onAccepted` — see "Editable mode"
  below.

- `rejected()`
  Qool extension: emitted when an edit attempt is rejected (validation
  fails; the text keeps its original value and the model is unchanged), so
  the host can notify the user. The official `ComboBox` has no such signal.

## Methods

This type defines no additional methods (inherits all methods from
`T.ComboBox`, notably `find()` and `textAt()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

ComboBox {
    model: ["Alpha", "Beta", "Gamma"]
    currentIndex: 1
    onActivated: console.log("selected:", currentText)
}

// Editable combo box: accept free text and add it to the model.
ComboBox {
    id: combo
    model: ListModel { id: model }
    editable: true
    validator: RegularExpressionValidator {
        regularExpression: /^[A-Za-z]+$/
    }
    onAccepted: {
        // editText already holds the user's input; the host owns the model.
        let idx = find(editText)
        if (idx < 0) {
            model.append({ text: editText })
            idx = model.count - 1
        }
        currentIndex = idx
    }
    onRejected: console.log("invalid input:", editText)
}

// Popup opens above the control.
ComboBox {
    model: ["A", "B", "C"]
    popupDirection: Qore.Above
}
```

### Editable mode

When `editable` is `true`, the control presents the text through a Qool
`EditableText` (dual-layer: display + edit session) and supports text-field
capabilities such as `selectTextByMouse`; the edit-session state machine is
handled by `EditableText` (unified commit and decision signals).

Input handling path: set `validator` to validate input — when an edit ends
(Enter / focus loss / Esc) the input is decided: acceptable
(`acceptableInput`) → `accepted()` is emitted and editing ends; not
acceptable → `rejected()` (Qool extension) is emitted and editing ends, the
text keeping its original value (**contract difference**: the official
implementation keeps editing when validation fails — this type always ends
the session and declares the rejection). After `accepted()` is emitted
`editText` is already synchronized to the user input; the host may use
`find()` to match a model item, set `currentIndex`, or append the new text to
the model — note that `currentIndex`/`currentText` do **not** update
automatically on commit: an accepted edit does not rewrite the model text —
the display follows `currentText`, and the host pulls it back after handling
the model; if the host does nothing, the edited text remains shown. While the
popup is open, pressing Enter activates the highlighted item and does not go
through the edit-commit path.

Esc / failed validation revert: the unified commit of the editing field
handles rejection — on `rejected()` the text keeps its original value (the
model is unchanged).
