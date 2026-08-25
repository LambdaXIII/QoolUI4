# ColorNameEdit

A color name display with click-to-edit — the replacement for the
removed `ColorEdit`, sharing the v3 edit-and-parse UX.

`ColorNameEdit` derives from `EditableText` and edits a `color`
(`value`). It shows the **nearest color name** for the current value
(`ColorHQ.colorName(value)`) and, on edit, parses typed input through the
`ColorHQ` name resolution back into `value`:

- **Display**: `displayItem` is a `ColorNumText` showing
  `ColorHQ.colorName(root.value)` — the nearest name, or the
  `#RRGGBB` / `#AARRGGBB` text when no provider knows the color.
- **Edit commit**: on `text` change, if the input is a valid color name
  or hex string (`ColorHQ.isValidColorName`) it is resolved with
  `ColorHQ.color(t)` and written to `value`; otherwise the input is
  **reverted** (`ensure_text()` restores the current name) — there is no
  transient fallback to a default, unlike the removed `ColorEdit`.
- **Self-consistency**: `onCompleted` seeds the text from the current
  value's name, so the component is coherent standalone.

This component deliberately does **not** use the module's numeric channel
convention (`x > 1` → `/1000`): a name/hex input like `"350"` is not a
valid color name and is reverted rather than interpreted as `0.35`.

## Properties

- `value : color` (default: `"white"`)
  The edited color. Displayed as its nearest name; written back from
  valid name/hex input.

Inherited from `EditableText`: `text`, `font`, `editable`, and the
`editingFinished` signal. See the `EditableText` documentation in
`Qool.Controls` for the inherited members.

## Signals

- `editingFinished()` (inherited from `EditableText`)
  Emitted when the edit ends (Enter or focus loss).

## Methods

This component defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: ca
    color: "navy"
    // Editing the name back to "red" writes ca.color = red.
}

ColorNameEdit {
    width: 160
    value: ca.color
}
```
