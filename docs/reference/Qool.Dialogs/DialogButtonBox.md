# DialogButtonBox

A skin specialization of Qt Quick Controls' **Basic style** `DialogButtonBox`,
exported under the bare name with **full interface compatibility** — a drop-in
replacement for `T.DialogButtonBox` in any container that accepts one
(`QoolDialog` footer, `T.Dialog` footer, `Popup`, `Page`).

Everything that makes a button box work comes from the base type untouched:
`standardButtons` instantiation, role-based signal dispatch (`accepted()` /
`rejected()` / `discarded()` / ...), the Container surface (`count`,
`itemAt()`, content management), platform-conventional button ordering,
standard-button text localization, and the 6.11 `defaultButton` /
`defaultStandardButton` machinery. This type only replaces the skin.

## Why the base is the style type, not the Template

`QtQuick.Templates.DialogButtonBox` carries the *algorithm* but not the
*content host*: it instantiates the standard buttons and computes the box's
implicit size, yet `contentItem` stays null until a style provides one (the
Basic style provides a `ListView`-based host that also does the positioning).

Without the host, standard buttons are created with no parent item: `count`
is right, `implicitWidth` / `implicitHeight` are right, and **nothing is ever
painted**. This is not theoretical — the box shipped in this shape and the
buttons were invisible while every sizing assertion passed.

The base is pinned to the Basic style (rather than following the application
style) so the host shape is deterministic; only the skin is ours. This makes
the module depend on Qt Quick Controls at runtime — a standard Qt deployment
assumption (the Basic style ships with every Qt installation).

## Differences from the base

- `padding: 0`
  Zero box padding — outer spacing belongs to the surrounding slot
  (e.g. `DialogSurface`'s `footer` slot and its `spacing`), so the box does
  not stack a second layer of insets.
- `spacing: 4`
  Literal value (deliberately not a `Style` token; inline button-row density,
  same standing as `ToolButton`'s padding literals). May be overridden
  per-instance as with any property.
- `background: null`
  The box is transparent: the dialog surface's own background shows through
  under the button row — buttons read as sitting on the dialog, not in a tray.
- `delegate: DialogButton {}`
  Standard buttons are created as `DialogButton` and therefore carry the
  role→semantic-color skin (Ok/Accept/Yes → positive, Discard/Destructive →
  negative, others neutral). See [DialogButton](DialogButton.md).
- `alignment` is not specialized
  Keeps the base default (buttons stretch to fill when unset); set it
  yourself for right-alignment.

**Zero intervention on existing buttons**: the box never restyles or rewires
buttons already inside it. A plain `T.AbstractButton` dropped in works
normally — it just has no semantic skin. To get semantic visuals, use
`DialogButton` explicitly.

## Sizing and visibility

The box reports `implicitWidth` / `implicitHeight` from its hosted buttons
(sum of their implicit sizes plus `spacing`), inherited from the style layer.
When placed in a slot that assigns only x / y / width (e.g.
`DialogSurface`'s `footer`), the box's height follows this implicit height and
its buttons are laid out and rendered by the inherited host.

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
