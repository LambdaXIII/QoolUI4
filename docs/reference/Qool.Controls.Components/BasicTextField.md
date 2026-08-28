# BasicTextField

The Qool single-line text field base — a **themed default `TextField`**
(standard behavior + Qool theme) with no behavior decisions mixed in.

`BasicTextField` is the themed version of the Qt Quick Templates
`TextField`: behavior is exactly official (single-line input, Enter ends
editing), only Qool theme defaults are provided — text three-colors and
vertical centering. It is symmetric to `BasicTextArea` (the multi-line
base). The series of editable controls (currently the `EditableText`
dual-layer edit layer) consumes this type as its edit base; the host can
also use it directly as a plain single-line text field.

## Properties

- `color : color` (default `Style.text`)
  Text color (Qool theme).

- `selectionColor : color` (default `Style.highlight`)
  Selection background color (Qool theme).

- `selectedTextColor : color` (default `Style.highlightedText`)
  Selected-text color (Qool theme).

- `verticalAlignment : int` (default `Text.AlignVCenter`)
  Vertical alignment — the single-line text field convention, declared
  explicitly following the `BasicTextArea` explicit-declaration convention
  (single-line `AlignVCenter` / multi-line `AlignTop`).

- `background` (default `null`)
  **No background (transparent):** the base is the bare template (not the
  styled `QtQuick.Controls.TextField`), so no default background is
  rendered — the Basic-style default background of `QC.TextField` does not
  apply to the Qool dual-layer editing scenario, and the dual-layer edit
  switching (`displayItem` ↔ edit layer) has no visual jump. The visual
  background is provided by the consumer (shell/layout background, e.g.
  `QoolControl`) or set via `background`.

Inherited from `QtQuick.Templates.TextField` (which inherits `TextInput`):
the official API is fully available — `text`, `placeholderText`,
`echoMode`, `readOnly`, `validator`, `inputMask`, `selectByMouse`,
`editingFinished()`, `textEdited()`, `accepted()`, `rejected()` and all
other `TextField`/`TextInput` members. See the Qt documentation for the
inherited members.

## Signals

This type defines no additional signals. `editingFinished()` and
`textEdited()` are inherited (official) and deliberately left unoccupied
for consumers: the edit-layer instance attaches the unified commit there —
an instance handler overrides the component definition, so this type must
not occupy them.

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Templates.TextField`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

BasicTextField {
    width: 200
    placeholderText: "Type something..."
    onTextEdited: console.log("edited:", text)
}
```

## Behavior notes

- **No background (transparent):** see `background` above.
- **Esc is not handled here:** this type does not change official behavior
  (Esc does not end editing); how an edit session ends (e.g. Esc commit)
  is a "session-end method" decision of the layer above (see
  `EditableText`).
- **`editingFinished`/`textEdited` are left to the consumer:** this type
  does not occupy them (an instance handler overrides the component
  definition — a future edit-layer consumer attaching a unified commit is
  not overridden).
