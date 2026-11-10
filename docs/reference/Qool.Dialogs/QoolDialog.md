# QoolDialog

Dialog window shell with a prebuilt `DialogSurface` (ADR-0021). `QoolDialog`
is an independent `Window` — deliberately **not** a `T.Dialog` subclass (see
ADR-0021 for the lineage investigation and the naming contract).

Window facts: `flags: Qt.Dialog | Qt.CustomizeWindowHint |
Qt.FramelessWindowHint`, `color: "transparent"`, no close button, no
dragging, no interactive resize.

## Properties

- `title : string` (inherited from `Window`)
  The dialog's single title entry: it is both the OS window title (taskbar /
  accessibility) and the title rendered by the prebuilt `DialogSurface`,
  whose `title` follows it. `title` is deliberately **not** redeclared on
  QoolDialog (shadowing `Window.title` is a semantic mess, per ADR-0021
  naming contract). The surface's `titleItem` is not exposed — use
  `DialogSurface` directly when a custom title rendering is needed.

- `header` / `content` / `footer : Item`
  Aliases to the prebuilt surface's slots, laid out vertically between the
  surface's background insets (see [DialogSurface](DialogSurface.md)).
  QoolDialog declares **no default property**: children written directly
  inside it become `Window.data` entries (children of the window's
  `contentItem`) and are not laid out by the surface — assign them to a slot
  instead.

- `modality : Qt::WindowModality` (default `Qt.WindowModal`)
  The dialog locks its host window (via automatic `transientParent`
  assignment) without blocking the whole application. Assign explicitly
  (e.g. `Qt.ApplicationModal`, `Qt.NonModal`) for special cases — must be
  set before the window is shown for the platform to honor it.

- `width` / `height`
  Defaults are `max(minimum size, surface implicit size)`. Explicit
  assignment takes effect and the content area expands to fill.

- `minimumWidth` / `minimumHeight`
  The QoolBox floor: the two horizontal (respectively vertical) cut-corner
  spaces plus twice the border width. Below this the background box shape
  degenerates, so the window cannot be shrunk past it. Derived from the
  surface's `backgroundSettings`, so a theme switch recomputes it.

- `maximumWidth` / `maximumHeight`
  Follow the current width/height: the window cannot be enlarged by the
  window manager. There are no resize affordances — normal use changes the
  size only through content or explicit assignment.

## Signals

- `accepted()`
  Emitted by [accept()](#methods).
- `rejected()`
  Emitted by [reject()](#methods); also the result of the Escape key and
  system close requests (Alt+F4 etc.).

## Methods

- `open()` / `close()`
  Thin forwarders to `visible`. `open()` also requests window activation, so
  the window-level Escape shortcut and any content focus are live immediately
  after opening.

- `accept()` / `reject()`
  The call surface for content-side buttons: close the window and emit the
  matching signal.

## Exit paths

Every exit ends in one of the two result signals — there is no third way out:

- **Escape** → `reject()`, i.e. exactly what a `Cancel` button
  (`RejectRole` → `rejected()`) does.
- **System close** (Alt+F4, window manager close) → `reject()`: the request is
  vetoed and converted to `rejected()`, so the window is never torn down
  behind the caller's back.
- **`accept()` / `reject()`** from your own content buttons.

Because the window is frameless, has no close button, and every platform
close request is routed to `reject()`, a dialog whose result must be
*accepted* has to offer an explicit button — but it can always be dismissed.

## Usage Example

```qml
import QtQuick
import Qool.Controls
import Qool.Dialogs

QoolDialog {
    id: dialog
    title: "Delete item?"

    content: Column {
        spacing: 8
        Text { text: "This cannot be undone." }
        Row {
            spacing: 8
            Button { text: "Delete"; onClicked: dialog.accept() }
            Button { text: "Cancel"; onClicked: dialog.reject() }
        }
    }
}
```

Open with `dialog.open()`; the result arrives via `onAccepted` /
`onRejected`.
