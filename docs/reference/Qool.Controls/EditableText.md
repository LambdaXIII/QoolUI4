# EditableText

An editable `Text` — the Qool dual-layer reinforced text component (display
layer + edit layer + edit model).

`EditableText` is an **editable Text**, not a replacement for the Qt
`TextField` — it does not promise the official `TextField` API surface. In
its resting state a display component (`displayItem`, a `Text` by default)
shows the presentation form of `text` (`displayText`), with semantics close
to `Text` (no click-to-focus, no text-field methods). Clicking the content
area or focusing (Tab) enters an edit session — an edit layer
(`BasicTextField`) overlays for editing, with semantics close to a
`TextInput`, and is unloaded when the session ends, restoring the display.
Session text and validation live in an edit model (an internal hidden
`TextInput`); the edit layer itself is stateless.

This type is the consumption base of the editing field for the series of
editable controls (ComboBox, SpinBox, ...).

## Properties

- `text : string`
  The main content (saved form, writable). Updated on edit end through
  `textFromEditText`; derived into the display through `displayTextFromText`
  otherwise.

- `displayText : string` (read-only)
  The display text — a read-only derivation. Equals `displayTextFromText(text)`
  in `Normal` echo mode; passwordized (each character replaced by
  `passwordCharacter`, falling back to "•" when empty) in
  `Password`/`PasswordEchoOnEdit`; the empty string in `NoEcho`. See
  "Password echo".

- `editText : string`
  The live edit-session channel (alias of the edit model's text — single
  source of truth). Follows `text` while not editing; two-way synchronized
  with the edit layer while editing. Writing it while not editing has no
  predefined semantics.

- `validator : var`
  Edit validation (aliased to the edit model, which consumes it). Qt
  validators work as usual (`DoubleValidator`, `IntValidator`,
  `RegularExpressionValidator`, ...). Validation happens in the edit model
  layer — the edit layer does not carry a validator (its end events are
  therefore unconditional, and the decision is executed by this type, see
  "Edit session").

- `editing : bool` (default `false`)
  Edit-session switch (Qool extension — the official API has no such
  property). `true` = a session is in progress (the edit layer is mounted;
  the host can read `editText`). The host can set it to enter/leave a
  session; click/focus/commit paths also drive it.

  **Note:** during session commit the state machine is locked — setting this
  property inside the `editingStarted`/`editingFinished` handler windows has
  **no effect** (the intent is dropped). Do not set `editing`
  synchronously in `editingStarted`/`editingFinished`/`accepted`/`rejected`
  handlers; to reopen editing after a rejection, defer with `Qt.callLater`
  or let the user click again.

- `readOnly : bool` (default `false`)
  Read-only switch (pure behavior — no style change): `true` does not start
  sessions (click/focus do nothing), and the control is not in the Tab
  focus chain; an explicit session (`editing = true`) is focusable/selectable
  but not editable. Becoming `true` mid-session commits the current edit
  through the unified path (submit or reject).

- `color : color` (default `Style.text`)
  Text color — shared by the display and the edit layer (`T.Control` has no
  `color`; Qool extension).

- `horizontalAlignment : int` (default `Text.AlignRight`),
  `verticalAlignment : int` (default `Text.AlignVCenter`)
  Text alignment — shared by display and edit layer (the edit layer inherits
  it through forwarding; switching has no visual jump). The right-aligned
  defaults follow the QoolUI control-internal text convention.

- `inputMask : string` (default `""`)
  Input mask — forwarded to the edit layer (official API alignment).

- `inputMethodHints : int` (default `Qt.ImhNone`)
  Input-method hints — forwarded to the edit layer (official API alignment).

- `wrapMode : int` (default `TextInput.NoWrap`)
  Wrap mode — forwarded to the edit layer (official API alignment).

- `selectByMouse : bool` (default `true`)
  Mouse selection switch — forwarded to the edit layer. The default allows
  mouse selection inside an edit session (the select-all-then-type session
  convention); it can be turned off.

- `echoMode : int` (default `TextInput.Normal`)
  Password echo mode — forwarded to the edit layer (official `TextInput`
  API alignment): `TextInput.Normal` (default, plain text) /
  `TextInput.Password` (masked; newly typed characters show briefly as plain
  text, see `passwordMaskDelay`) / `TextInput.NoEcho` (shows nothing) /
  `TextInput.PasswordEchoOnEdit` (plain while editing, masked otherwise).
  In non-`Normal` modes copy/cut are disabled inside the edit layer
  (built-in, official — prevents bypassing the password feature). See
  "Password echo".

- `passwordCharacter : string` (default `""`)
  Password mask character — forwarded to the edit layer. Used for masking in
  `Password`/`PasswordEchoOnEdit`. Empty means "use the platform theme
  character" (the edit layer picks it up automatically); **note**: the
  non-editing display layer falls back to the fixed character "•" when this
  is empty — the two defaults may differ (platform character while editing
  vs "•" while not), so set this explicitly when the two must match.
  Multi-character values use the first character; the edit layer ignores the
  empty value (uses the platform default).

- `passwordMaskDelay : int`
  Password mask delay — forwarded to the edit layer: the milliseconds a newly
  typed character stays plain before being masked in `Password` mode.
  Default unset (forwarding keeps the platform default, officially 600 ms).

- `displayItem : Item`
  The display component (the content body — an `Item` instance, geometry
  self-managed). Defaults to a `Text` bound to `displayText`/font/color/
  alignment with `anchors.fill: parent`. Can be replaced wholesale (e.g. with
  another presentation component). Hidden while editing (opacity switch — not
  unloaded; restored when the session ends).

  **Design intent — replacing `displayItem` decouples display from `text`.**
  The default `Text` exists as a ready upper layer only; overriding
  `displayItem` is the sanctioned way to detach the display from the
  `text`/`displayText` chain — bind the replacement's content to any
  external source (a real data value, a different derivation), and `text`
  degrades to the pure saved form (edit baseline + commit target). The
  edit session is unaffected: it always opens with `editText` (the saved
  form) and commits through `textFromEditText`. When the display no longer
  derives from `text`, the host keeps the edit baseline fresh — e.g. a
  `Binding` writing `text` while not editing — otherwise the next edit
  session opens with a stale value. The default display layer stays
  available and is simply not used.

- `displayTextFromText : var` (default: identity function)
  Pluggable function: `text` (saved form) → display text — the
  presentation-process conversion (masking/formatting and other display
  transforms). Overriding the same-named function in a derived class takes
  effect (QML function shadowing). Semantically independent of
  `textFromEditText` (see below).

- `textFromEditText : var` (default: identity function)
  Pluggable function: edit text → `text` (saved form) — the commit-process
  conversion (normalization: trim/strip; direct-edit-value semantics).
  Independent of `displayTextFromText` — the two are not assumed to be
  inverses; implementing them as inverse operations is a valid usage (edit
  presentation form), not a contract.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`): controls animations and high-cost style effects
  ("high-performance mode vs full effects" switch).

Inherited from `T.Control`: `font`, `padding`, `enabled`, `focus`,
`activeFocusOnTab` (defaults to `!readOnly` here), `implicitWidth`/
`implicitHeight` and all other `Control` members. See the Qt documentation
for the inherited members. `font.pixelSize` defaults to `Style.controlTextSize`.

## Signals

- `editingStarted()`
  Entered an edit session (the edit layer is ready; the host can read
  `editText`).

- `editingFinished()`
  Announces the moment editing ended (TextInput-aligned semantics) — fired
  before the decision signals (`accepted`/`rejected`); on accept `text` is
  already written, so the host can read it reliably.

- `accepted()`
  The decision result of an end attempt (Qool extension — an independent
  signal, not an internal forward): the input was accepted and written to
  `text`. Only fired when the input differs from the current `text`
  (identical = no processing, no announcement).

- `rejected()`
  The decision result of an end attempt (Qool extension): the input was
  rejected and not written (the host can notify the user). Only fired when
  the input differs from the current `text`.

- `textEdited()`
  User-edit event (forwarded from the edit layer — emulates the official
  `TextField` semantics): fired when the user modifies the text during an
  edit session; unrelated to the commit decision.

## Methods

This type defines no additional methods (inherits all methods from
`T.Control`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

EditableText {
    width: 200
    text: "hello"
    validator: RegularExpressionValidator {
        regularExpression: /^[a-z]+$/
    }
    onAccepted: console.log("committed:", text)
    onRejected: console.log("rejected input")
    onEditingStarted: console.log("editing:", editText)
}

// Password field: masked display, plain while typing.
EditableText {
    width: 200
    text: "secret"
    echoMode: TextInput.Password
    passwordCharacter: "*"
}
```

### Edit session

Entering: click on the content area / focus (Tab) / the host sets
`editing = true`. On assembly the edit layer is filled with the current
`editText`, `selectAll()` (typing replaces everything) and grabs focus.

End attempt (Enter / focus loss / Esc / the host sets `editing = false`):
the edit layer's `editingFinished` fires unconditionally (it carries no
validator) → this type decides on the edit model's `acceptableInput` →
accepted: `text = textFromEditText(...)` + `accepted()`; rejected: no write
+ `rejected()`; input identical to the current `text`: no processing (neither
signal fires) → `editingFinished` announces the end. Esc is treated as
ordinary focus loss.

The decision does not depend on the edit-layer lifecycle (the edit model is
resident — programmatic ends and already-unloaded edit layers can still be
decided).

### Relation to the Qt TextField

`EditableText` is **not** a replacement implementation of the Qt `TextField`
and does not promise the official `TextField` API surface; hosts should not
use it as one. It is Qool's own editable-Text concept:

- Dual-layer structure: the display layer (`displayItem`, `Text` semantics)
  and the edit session (`BasicTextField` overlay, `TextInput` semantics) are
  separate; `displayText` is a read-only derivation.
- Edit-session state machine: `editing`/`editingStarted()`/`editingFinished()`/
  `accepted()`/`rejected()` are Qool extensions — the official API has no
  session switch or matching signals (the official `accepted` fires only on
  Enter with acceptable input; here `accepted` is the decision result of an
  end attempt, a different source semantics).
- Bare control: no shell visuals (background box/title/shell covers) — the
  host provides them by wrapping e.g. `QoolControl` (same positioning as
  SpinBox).

### Password echo

Set `echoMode` to `TextInput.Password` / `TextInput.PasswordEchoOnEdit` to
enable password input. Masking applies on both layers:

- Display layer (not editing): `displayText` is a passwordized derivation —
  the result of `displayTextFromText(text)` has each character replaced by
  `passwordCharacter` ("•" fallback when empty). The plug point is preserved
  — passwordization applies after it.
- Edit layer (edit session): a real `TextInput` — in `Password` newly typed
  characters stay plain briefly (`passwordMaskDelay`) before masking; in
  `PasswordEchoOnEdit` plain while editing, masked after losing focus.

copy/cut are disabled in non-`Normal` echo modes (built into the edit layer,
official — prevents bypassing the password feature). `readOnly` + `echoMode`:
non-editing read-only display is masked the same way (the display layer
handles it uniformly) — a read-only password field hides its plaintext too.
`NoEcho`: `displayText` is the empty string (nothing is shown) — highest
security, only for purely hidden inputs that never need confirmation.
