# DialogSurface

Container-agnostic dialog surface: title + content area + dialog-themed
background. `DialogSurface` derives from `BasicControl` and does not assume
any container semantics by itself — embed it in `QoolDialog` (prebuilt) or
assemble it into a `Popup` yourself for overlay semantics (dim/closePolicy
come from the `Popup`, not from this type).

The only override against `BasicControl` is the `backgroundSettings` default
value, switched to the dialog token group:

- `cutSizeTL: Style.dialogCutSize` (TL single-corner cut, per repo visual
  language; TR/BL/BR stay 0)
- `borderWidth: Style.dialogBorderWidth`
- `borderColor: Style.accent`
- `fillColor: Style.window`

Because every value is a `Style` token binding, theme switches restyle the
surface without any adaptation.

Title/title slot, content area, implicit sizing, padding, and
`containmentMask` are all inherited from `BasicControl` (the title slot is
rendered by its background `QoolBGBox`); see [BasicControl] and the Qt
`T.Control` documentation for those contracts.

## Properties

- `title : string` (inherited from `BasicControl`)
  Sets the dialog title, rendered by the default title item.

- `titleItem : Item` (inherited from `BasicControl`)
  Replaces the default title rendering (e.g. an icon + text row). The item
  is reparented into the background box; anchor margins already account for
  the cut-corner safe area.

- `backgroundSettings` (inherited from `BasicControl`, default overridden as
  listed above)
  Further overrides remain possible per-instance.

All other members: inherited from `BasicControl` / `T.Control`.

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
}

// Overlay dialog assembled by hand: dim + outside-click close come from Popup
Popup {
    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: 320
    height: 200

    DialogSurface {
        anchors.fill: parent
        title: "Confirm"
    }
}
```

[BasicControl]: ../Qool.Controls.Components/index.md
