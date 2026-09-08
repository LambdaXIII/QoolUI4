# DialogButtonBox

A specialization of QtQuick.Templates' `DialogButtonBox`, exported under the
bare name with **full interface compatibility** — a drop-in replacement for
`T.DialogButtonBox` in any container that accepts one (`QoolDialog` footer,
`T.Dialog` footer, `Popup`, `Page`).
All button-box mechanics come from the Template layer untouched:
`standardButtons` instantiation, role-based signal dispatch
(`accepted()` / `rejected()` / `discarded()` / ...), the Container surface
(`count`, `itemAt()`, content management), platform-conventional
button ordering, standard-button text localization (via the platform theme +
qtbase translations), and the 6.11 `defaultButton` / `defaultStandardButton`
machinery. This type only replaces the skin.

One upstream behavior is load-bearing here (verified against the Qt 6.11
source): standard buttons are instantiated from the `delegate`; with no
delegate, standard buttons are not created at all.

## Differences from T.DialogButtonBox

- `padding: 0`
  Zero box padding — outer spacing belongs to the surrounding slot
  (e.g. `DialogSurface`'s `footer` slot and its `spacing`), so the box does
  not stack a second layer of insets.
- `spacing: 4`
  Literal value (deliberately not a `Style` token; inline button-row density,
  same standing as `ToolButton`'s padding literals). May be overridden
  per-instance as with any property.
- No `background` declared
  The Template default is a null background, so the box is transparent: the
  dialog surface's own background shows through under the button row —
  buttons read as sitting on the dialog, not in a tray.
- `delegate: DialogButton {}`
  Standard buttons are created as `DialogButton` and therefore carry the
  role→semantic-color skin (Ok/Accept/Yes → positive, Discard/Destructive →
  negative, others neutral). See [DialogButton](DialogButton.md).
- `alignment` is not specialized
  Keeps the Template default (buttons stretch to fill when unset); set it
  yourself for right-alignment.

**Zero intervention on existing buttons**: the box never restyles or rewires
buttons already inside it. A plain `T.AbstractButton` dropped in works
normally — it just has no semantic skin. To get semantic visuals, use
`DialogButton` explicitly.

## Sizing

The box computes its own `implicitWidth` / `implicitHeight` from the buttons
(sum of their implicit sizes plus `spacing`), following the Basic style's
approach: the Template layer's built-in contentItem is a bare `Item` and does
not size the control. Without these declarations the box reports zero
implicit size — container-driven sizing (e.g. `QoolDialog` deriving its size
from the `footer` slot) then collapses, slots can hand out negative widths,
and buttons become invisible. When placed in a slot that assigns only
x / y / width (e.g. `DialogSurface`'s `footer`), the box's height follows
this implicit height.

## Usage

```qml
import QtQuick
import Qool.Dialogs

QoolDialog {
    id: root

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        onAccepted: root.accept()
        onRejected: root.reject()
    }
}
```

The two handler lines are the entire wiring convention: click paths
(OK / Cancel), `Esc`, and window-close all end in `root.accept()` /
`root.reject()` and stay explicit.

The attached properties `T.DialogButtonBox.buttonRole` and
`T.DialogButtonBox.buttonBox` remain available on the box's buttons exactly
as in the Template type. Always write the attached with the `T.` qualifier:
the bare name `DialogButtonBox` resolves to this module's own component, not
the Template's attached-property host.
