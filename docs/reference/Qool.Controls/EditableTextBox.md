# EditableTextBox

A multi-line text input finished control — a `BasicTextArea` (Components
base) plus scrolling (a `ScrollView` combination).

`EditableTextBox` is the multi-line finished product of the Qool text
component series: an out-of-the-box multi-line text input. Give it a size
(`width`/`height` or `anchors.fill`) and it accepts input; content that
exceeds the viewport scrolls vertically. The text API is forwarded directly
to the inner text area (`BasicTextArea` — its Qool themed defaults of text
three-colors / font / `Wrap` / `AlignTop` are all kept). The host only
interacts with this type; the inner text object and editing-mechanism
details are not exposed (there is **no edit session** — this is independent
of `EditableText`'s single-line session mechanism; only the naming is
related).

## Properties

The following properties/signals are forwarded from the inner `BasicTextArea`:

- `text : string`
  The text content.

- `readOnly : bool`
  Read-only (official semantics). While read-only, `selectByMouse` is
  disabled automatically (the inner area binds `selectByMouse: !readOnly`).

- `color : color` (default `Style.text`)
  Text color.

- `selectionColor : color` (default `Style.highlight`)
  Selection background color.

- `selectedTextColor : color` (default `Style.highlightedText`)
  Selected-text color.

- `wrapMode : int` (default `TextEdit.Wrap`)
  Wrap mode — text wraps at the viewport width (vertical scrolling
  semantics: content height grows with the text, no horizontal scroll).
  Switching to `NoWrap` can introduce horizontal scrolling.

- `textFormat : int` (default `PlainText`)
  Text format.

- `selectByMouse : bool` (default `true`, official default)
  Mouse selection.

- `font` is **not** forwarded: the base `ScrollView`'s `Control.font` is a
  final property that QML cannot redeclare; the inner text area defaults to
  `Style.controlTextSize` (Qool theme). Override the inner font by composing
  `ScrollView`/`TextArea` yourself.

Inherited from `ScrollView` (which inherits `QtQuick.Controls.ScrollView` /
`Pane`): `contentData`, `effectiveScrollBarWidth`,
`effectiveScrollBarHeight`, `ScrollBar.vertical`/`ScrollBar.horizontal`
attached properties, `padding` and all other `ScrollView`/`Pane`/`Control`
members. See the Qt documentation for the inherited members. This type does
not change official behavior; it only presets Qool-themed scroll bars and
forwards the text API.

## Signals

- `textEdited()`
  Emitted when the user edits the text (forwarded from the inner text area;
  the edited text is read via `text` — the no-argument semantics of the
  `EditableText` series).

- `editingFinished()`
  Emitted when editing ends (focus loss) (forwarded from the inner text
  area).

## Methods

This type defines no additional methods (inherits all methods from
`ScrollView`).

## Usage Example

```qml
import QtQuick
import Qool.Controls

EditableTextBox {
    width: 320
    height: 200
    text: "Multi-line\ninput"
    wrapMode: TextEdit.Wrap
    onTextEdited: console.log("changed:", text)
}

// Read-only notes view.
EditableTextBox {
    anchors.fill: parent
    readOnly: true
    text: notesModel.text
}
```

## Behavior and usage

- Give the host a size (`width`/`height` or `anchors.fill`); the default
  implicit size is 240×120 (a fixed viewport — it does not grow with the
  text).
- Enter inserts a newline, Tab inserts a tab character, `placeholderText`
  works — all official `TextArea` behavior, unchanged by this type.
- No background (transparent): the visual background is provided by the
  host's shell (the `BasicTextArea` bare-control convention).
- Text padding and scroll position (`contentY`) are not exposed — editing
  details are not public; hosts that need them compose
  `ScrollView`/`TextArea` directly.

## Scrolling

The scroll bars are preset by `ScrollView` (Qool theme — both vertical and
horizontal are Qool `ScrollBar`; the horizontal one is `AsNeeded` and does
not appear under the default `Wrap`). Geometry layout, content giving-way and
policy control are described by `ScrollView`. Content size grows
automatically with the text, background decorations do not scroll with the
content, and clipping is automatic — the official `ScrollView`-on-`TextArea`
integration guarantee.
