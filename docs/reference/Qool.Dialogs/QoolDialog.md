# QoolDialog

Dialog window shell with a prebuilt `DialogSurface` (ADR-0021). `QoolDialog`
is an independent `Window` — deliberately **not** a `T.Dialog` subclass (see
ADR-0021 for the lineage investigation and the naming contract).

Window facts: `flags: Qt.Dialog | Qt.CustomizeWindowHint |
Qt.FramelessWindowHint`, `color: "transparent"`, no close button, no
dragging, no interactive resize.

## Properties

- `surface : DialogSurface` (readonly alias)
  The prebuilt surface inside the window. The title entry points are
  `surface.title` / `surface.titleItem`. `title` is intentionally **not
  redeclared** on QoolDialog (shadowing `Window.title` is a semantic mess,
  per ADR-0021 naming contract); `Window.title` internally follows
  `surface.title` for the taskbar / accessibility.

- `content` (default property, redirected)
  Children written inside `QoolDialog` land in the surface's content area.

- `modality : Qt::WindowModality` (default `Qt.WindowModal`)
  The dialog locks its host window (via automatic `transientParent`
  assignment) without blocking the whole application. Assign explicitly
  (e.g. `Qt.ApplicationModal`, `Qt.NonModal`) for special cases — must be
  set before the window is shown for the platform to honor it.

- `width` / `height`
  Defaults are derived from the surface's implicit size with a 200×200 floor
  (near-empty content cannot collapse the window). Explicit assignment takes
  effect and the content area expands to fill.

- `minimumWidth`/`maximumWidth`/`minimumHeight`/`maximumHeight`
  Follow the current width/height: interactive resize is locked out while
  programmatic assignment stays possible.

## Signals

- `accepted()`
  Emitted by [accept()](#methods).
- `rejected()`
  Emitted by [reject()](#methods); also the result of the Escape key and
  system close requests (Alt+F4 etc.).

## Methods

- `open()` / `close()`
  Thin forwarders to `visible`.

- `accept()` / `reject()`
  The call surface for content-side buttons: close the window and emit the
  matching signal. Escape and system close requests are routed to
  `reject()` uniformly.

## Usage Example

```qml
import QtQuick
import Qool.Controls
import Qool.Dialogs

QoolDialog {
    id: dialog
    surface.title: "Delete item?"

    Column {
        anchors.centerIn: parent
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
