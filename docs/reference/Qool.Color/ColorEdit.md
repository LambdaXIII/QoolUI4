# ColorEdit

A color name display with click-to-edit, resolving names and hex strings
back to colors.

`ColorEdit` is a two-state component:

1. **Display state**: shows the nearest color name for `currentColor`,
   rendered by `ColorNameHQ.name(currentColor)`, right-aligned.
2. **Edit state**: clicking (IBeam cursor) enters edit mode; the editor
   shows the display text, selects it all, and parses input live back into
   `currentColor`. Enter or focus loss ends the edit and emits
   `editingFinished`.

### Input parsing

The editor text is resolved through
`ColorNameHQ.color(text, defaultColor)`, which accepts color names or
`#RRGGBB` / `#AARRGGBB` hex strings. On a parse failure — including any
intermediate input state (e.g. `"re"` before `"red"` is complete) —
`currentColor` is set to `defaultColor`. The transient fallback during
typing is inherited v3 behavior, not a bug.

This component is a *color name* input and deliberately does not use the
module's numeric channel convention (`x > 1` → `/1000`): typing `"350"` fails
parsing and falls back to the default color instead of meaning 0.35.

### Edit round trip

- Entering edit mode: `edit()` (by click or programmatically) — the text
  is set to the display text, selected, the editor is shown and grabs
  focus.
- Leaving edit mode: `TextInput.editingFinished` (Enter or focus loss) —
  hides the editor and emits `editingFinished`. Focus loss counts as
  commit (there is no "cancel" semantics; the content has already been
  parsed back), matching v3.
- While editing, `currentColor` changes live with the input and the
  display text is hidden.

### Defaults

`currentColor` defaults to `defaultColor` (`"white"`), so the component is
self-consistent standalone — it works without binding to a
`ColorAssistant`.

## Properties

- `currentColor : color` (default: `defaultColor`)
  The current color. In display state it is rendered as a color name by
  `ColorNameHQ.name()`; in edit state it is parsed back from the input
  text (falling back to `defaultColor` on failure).

- `defaultColor : color` (default: `"white"`)
  The default color, also the fallback color when parsing fails.

- `editing : bool` (read-only)
  Whether the component is in edit state (equals the editor visibility).

- `horizontalAlignment : int` (default: `Text.AlignRight`)
  The horizontal alignment of the text.

- `font : font` (default: `PixelFont.normal`, MozartNBP 24 px)
  The font shared by display and editor.

## Signals

- `editingFinished()`
  Emitted when the edit ends (Enter or focus loss).

## Methods

- `void edit()`
  Programmatically enters edit state (equivalent to a click).

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorEdit {
    id: colorName
    width: 160
    currentColor: assistant.color   // bind to a shared ColorAssistant
    onEditingFinished: console.log("committed:", colorName.currentColor)
}
```
