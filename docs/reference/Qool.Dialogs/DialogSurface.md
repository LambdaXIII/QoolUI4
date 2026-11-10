# DialogSurface

Container-agnostic dialog surface: a `QoolBGBox` background plus a title slot
and three vertical content slots (`header` / `content` / `footer`).
`DialogSurface` assumes no container semantics by itself — embed it in
`QoolDialog` (prebuilt) or assemble it into a `Popup` yourself for overlay
semantics (dim/closePolicy come from the `Popup`, not from this type). Note
that `Popup.focus` defaults to `false`, so `Popup.CloseOnEscape` never fires
unless the popup is told to take focus.

The background is a `QoolBGBox` configured with the dialog token group:

- `cutSizeTL: Style.dialogCutSize` (TL single-corner cut, per repo visual
  language; TR/BL/BR stay 0)
- `borderWidth: Style.dialogBorderWidth`
- `borderColor: Style.accent`
- `fillColor: Style.window`

Because every value is a `Style` token binding, theme switches restyle the
surface without any adaptation.

## Properties

- `title : string`
  The dialog title, rendered by the background box's default title item
  (top-right, inside the cut-corner safe area). An empty title hides the
  label.

- `titleItem : Item`
  Replaces the default title rendering (e.g. an icon + text row). The item is
  reparented into the background box and positions itself — anchor it to the
  box's top-right corner (see `PageFrame` in the example for the conventional
  margins). Only the default title item carries the cut-corner safe margins.

- `header : Item` (default: empty `Item`)
- `content : Item` (default: empty `Item`)
- `footer : Item` (default: empty `Item`)
  The three slots, laid out vertically between the background's reported
  content insets, separated by `spacing`: `header` at the top, `footer` at
  the bottom, `content` filling the middle. An assigned item is reparented to
  the surface and receives the slot's x / y / width; `content` additionally
  receives the remaining height, while `header` / `footer` keep their own
  height. `DialogSurface` has no default property — children written directly
  inside it are plain visual children and are not laid out by the slots.

- `spacing : real` (default `Style.windowElementSpacing`)
  Vertical gap between the slots.

- `backgroundSettings : QoolBoxSettings`
  The background box's settings; defaults to the dialog token group above.
  Per-instance overrides remain possible.

## Sizing

- `implicitWidth`: `max(background implicit width, leftSpace + max(header,
  content, footer implicit widths) + rightSpace)`
- `implicitHeight`: `max(background implicit height, topSpace + header.height
  + content.implicitHeight + footer.height + spacing × 2 + bottomSpace)`

Content-driven sizing therefore follows the content item's implicit height:
give the content item a meaningful implicit size (e.g. a `Column`) if the
surface is meant to size to its content.

`containmentMask` is the background box: pointer events outside the QoolBox
profile are rejected.

## Usage Example

```qml
import QtQuick
import QtQuick.Controls
import Qool.Dialogs

// Standalone panel
DialogSurface {
    title: "Confirm"
    width: 320
    height: 200

    content: Column {
        spacing: 8
        Text { text: "Delete this item?" }
    }
}

// Overlay dialog assembled by hand: dim + outside-click close come from Popup
Popup {
    modal: true
    dim: true
    focus: true   // Popup.focus 默认 false——不取焦点，CloseOnEscape 收不到 Esc
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Item {}   // the surface draws its own QoolBox background
    width: 320
    height: 200

    DialogSurface {
        anchors.fill: parent
        title: "Confirm"
    }
}
```
