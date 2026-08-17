# BasicTextArea

The Qool multi-line text field base — a **themed default `TextArea`**
(standard behavior + Qool theme) with no behavior decisions mixed in.

`BasicTextArea` is the themed version of the Qt Quick Controls `TextArea`:
behavior is exactly official (Enter inserts a newline, Tab inserts a tab
character, `placeholderText` works, no built-in scrolling), only Qool theme
defaults are provided — text three-colors, font, wrap mode and alignment.
It is symmetric to `BasicTextField` (the single-line base): the host can use
it directly as a multi-line text field, or as the edit-layer base of a
future multi-line dual-layer edit session.

## Properties

- `color : color` (default `Style.text`)
  Text color (Qool theme).

- `selectionColor : color` (default `Style.highlight`)
  Selection background color (Qool theme).

- `selectedTextColor : color` (default `Style.highlightedText`)
  Selected-text color (Qool theme).

- `font : font`
  Font — defaults to `Style.controlTextSize` pixel size (Qool theme). Can be
  overridden wholesale as usual.

- `wrapMode : int` (default `TextEdit.Wrap`)
  Wrap mode — the multi-line text field convention (the official default is
  `NoWrap`). Text wraps at the control's width; the host can switch back to
  the official default or another mode.

- `verticalAlignment : int` (default `TextEdit.AlignTop`)
  Vertical alignment — the official `TextEdit` default, declared explicitly
  following the `BasicTextField` explicit-declaration convention (single-line
  `AlignVCenter` / multi-line `AlignTop`).

- `background` (default `null`)
  **No background (transparent):** the visual background is provided by the
  consumer (shell/layout background) or set via `background` — same
  convention as `BasicTextField`. `QC.TextArea` carries a Basic-style default
  background (gray `#787878`), which conflicts with this type's transparent
  contract — it is explicitly removed.

Inherited from `QtQuick.Controls.TextArea` (which inherits `TextEdit`): the
official API is fully available — `text`, `placeholderText`,
`placeholderTextColor`, `readOnly`, `selectByMouse`, `textFormat`,
`contentHeight`, `editingFinished()`, `textEdited()`, `TextArea.flickable`
attached property, and all other `TextArea`/`TextEdit` members. See the Qt
documentation for the inherited members.

## Signals

This type defines no additional signals. `editingFinished()` and
`textEdited()` are inherited (official) and deliberately left unoccupied for
consumers: the edit-layer instance attaches the unified commit there — an
instance handler overrides the component definition, so this type must not
occupy them.

## Methods

This type defines no additional methods (inherits all methods from
`QtQuick.Controls.TextArea`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

BasicTextArea {
    width: 300
    height: 150
    placeholderText: "Type something..."
    wrapMode: TextEdit.Wrap
    onTextEdited: console.log("edited:", text)
}
```

## Behavior notes

- **No background (transparent):** see `background` above.
- **Esc is not handled here:** this type does not change official behavior
  (Esc does not end editing); how an edit session ends (e.g. Esc commit) is
  a "session-end method" decision of the layer above.
- **`editingFinished`/`textEdited` are left to the consumer:** this type
  does not occupy them (an instance handler overrides the component
  definition — a future edit-layer consumer attaching a unified commit is
  not overridden).
- **No built-in scrolling:** official `TextArea` behavior (`TextEdit` does
  not scroll) — compose it inside a `ScrollView`/`Flickable` when scrolling
  is needed (`TextArea.flickable` is available).
- **`placeholderText`/`placeholderTextColor`:** official properties, usable
  directly.

The base class is `QC.TextArea` (Qt Quick Controls, not `T.TextArea`): the
T version has no scroll capability inside a `ScrollView`/`Flickable`
(content size does not hook up); the QC version auto-integrates when placed
in a `ScrollView` (content size automatic / background does not scroll /
clip automatic).
