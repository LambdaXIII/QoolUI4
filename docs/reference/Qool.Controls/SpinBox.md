# SpinBox

A numeric stepper based on `QtQuick.Templates.DoubleSpinBox` (int/double
unified).

`SpinBox` is a numeric step control — a **bare control** with no shell
visuals; the shell (background box, title, label, content padding, shell
covers) is provided by the host wrapping it (e.g. in a `QoolControl`). It
inherits `QtQuick.Templates.DoubleSpinBox`, so the official API is
compatible — `from`, `to`, `stepSize`, `decimals`, `value`,
`valueModified()`, `editable`, `validator`, `textFromValue()`/`valueFromText()`,
`increase()`/`decrease()` all work as documented by Qt. On top of the
official interface it provides an edit session (via an internal
`EditableText`) and Qool extension signals (see below).

## Properties

- `currentValue : var`
  Hook: by default bound to `value` (follows stepping and commits); assigning
  it breaks the binding — for the "display value independent of the internal
  value" scenario. One of the three extension hooks.

- `editText : string`
  Qool extension — edit-in-progress text write-back channel (same style as
  `ComboBox.editText`; the template has no such property). Input during an
  edit session syncs here live, one-way (edit field → this property), for
  the host to observe the editing process. The template exposes no
  `editText`; it must be declared explicitly.

- `horizontalAlignment : int` (default `Text.AlignHCenter`)
  Horizontal alignment of the content.

- `verticalAlignment : int` (default `Text.AlignVCenter`)
  Vertical alignment of the content.

- `inputMethodHints : int` (default `Qt.ImhFormattedNumbersOnly`)
  **Contract difference**: the official default is `ImhDigitsOnly` (the
  virtual keyboard would not allow a decimal point or minus sign); Qool
  switches to `ImhFormattedNumbersOnly` so decimals and negatives can be
  typed. A host assignment still overrides this default.

- `validator` (default)
  A `DoubleValidator` following the official Basic style: `bottom`/`top`
  take `min`/`max` of `from`/`to` (supports inverted ranges where
  `from > to`), `decimals` limits input precision.

Inherited from `T.DoubleSpinBox`: `from`, `to`, `value`, `stepSize`,
`decimals`, `editable`, `locale`, `valueModified()`, `textFromValue()`,
`valueFromText()`, `up`/`down` indicators, `increase()`, `decrease()` and all
other `DoubleSpinBox`/`Control` members. See the Qt documentation for the
inherited members. `font.pixelSize` defaults to `Style.controlTextSize`. The
default implicit size is 100 × 35 (the transparent background `Item` is
purely a sizing mechanism — the shell's background overlays it).

## Signals

- `accepted()`
  Qool extension — emitted when an edit end attempt is accepted (the input
  passes validation and parses to a finite number; `value` is already
  updated, so the host reads `value` reliably; when the value actually
  changed, `valueModified()` was already emitted first).

- `rejected()`
  Qool extension — emitted when an edit end attempt is rejected
  (validation failed or the parse failed; `value` stays unchanged — the
  display falls back to the original value), so the host can notify the
  user. The official `T.DoubleSpinBox` has no such signals — they are
  declared explicitly and forwarded from the internal edit field.

## Methods

This type defines no additional methods (inherits all methods from
`T.DoubleSpinBox`, notably `increase()`, `decrease()`, `textFromValue()`,
`valueFromText()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

SpinBox {
    from: 0
    to: 100
    stepSize: 1
    value: 42
    onValueModified: console.log("committed:", value)
}

// Decimal values: decimals are validated by the default validator.
SpinBox {
    from: -10
    to: 10
    stepSize: 0.5
    decimals: 1
}

// Observe and steer the edit session.
SpinBox {
    from: 0
    to: 100
    editable: true
    onEditTextChanged: console.log("typing:", editText)
    onAccepted: console.log("accepted", value)
    onRejected: console.log("invalid input — value kept:", value)
}
```

## Editing

The edit session is handled by the internal `EditableText` (dual-layer):
click/focus enter editing, Enter/focus-loss/Esc end and decide. Input that
passes the `validator` **and** parses to a finite number is accepted
(`value` updated + `accepted()`); otherwise it is rejected (`value`
unchanged + `rejected()`) — **contract difference**: the official
implementation parses invalid text into something like 0 and clamps it in —
this type falls back to the original value and never writes dirty data.
Pressing an indicator while editing ends the edit first (the unified commit
decides), then the template's press-repeat steps — the commit-then-step
order guarantees no input is lost. `editable` turning off mid-edit is handled
by `EditableText` itself (read-only → unified commit), zero code here.

### Behavior differences (vs the official Qt implementation)

- `inputMethodHints` defaults to `ImhFormattedNumbersOnly` (the official
  default is `ImhDigitsOnly` — no decimal point / minus sign on virtual
  keyboards).
- Edit commit/revert: invalid input reverts to the original value (the
  official implementation parses and writes).
- Scrolling the wheel while editing still steps (same as official — the text
  field does not consume wheel events); note that a commit re-parses the
  edit session's text, so a step made mid-edit may be reverted by the edited
  text on commit (single-layer official semantics differ: display and edit
  share one text object, so commit equals the stepped value).
- Pressing an indicator while editing: ends editing first, then steps
  (official keeps editing and may show stale text).

## Extension points (the three hooks)

- `currentValue`: display value independent of the internal value (assignment
  breaks the default binding).
- `textFromValue` / `valueFromText`: override the custom display/parse
  format (derived classes — official extension points; override as a pair).
- `increase` / `decrease`: override the stepping logic (QML same-name
  function shadowing).
