# DialogButton

A dialog-domain button with the role→semantic-color mapping built into
itself. Used as the [DialogButtonBox](DialogButtonBox.md) delegate (default)
or placed by hand inside one — both paths get the identical body and visual.

Root type is `T.AbstractButton` with a self-declared
`property bool highlighted: false` (the repo's `Button` precedent): it
deliberately does not claim generic-button API surface beyond the abstract
contract. The box places no type requirement on its delegate — this skin
simply is the one it instantiates.

## Role → visual mapping

The role is read from the qualified attached property
`T.DialogButtonBox.buttonRole`. Exactly three roles map to semantic colors;
everything else stays neutral.

| role                          | fill              | border            | text                                          |
| ----------------------------- | ----------------- | ----------------- | --------------------------------------------- |
| `AcceptRole` / `YesRole`      | `Style.positive`  | `Style.positive`  | `ThemeHQ.recommendForeground(fillColor)`      |
| `DestructiveRole`             | `Style.negative`  | `Style.negative`  | `ThemeHQ.recommendForeground(fillColor)`      |
| any other (incl. no role)     | `Style.button`    | `Style.controlBorderColor` | `Style.buttonText`                   |

- Border width is always `Style.controlBorderWidth`.
- Semantic foreground text goes through
  `ThemeHQ.recommendForeground(bgColor)` (light/dark defaults `white`/`black`)
  so text stays readable on positive/negative fills; this is the contrast
  contract for semantic fills.
- All values are `Style` bindings: theme switches restyle the button with
  zero adaptation.

The rest of the skin follows the repo `ToolButton` recipe: `QoolBoxSettings`
+ `QoolBox` background, pressed/highlight/locked covers, a centered bare
`Text` contentItem, `padding` 2/4, font size `Style.controlTextSize`.

## Properties

- `highlighted : bool` (default `false`)
  Second emphasis channel: drives the highlight cover's opacity together
  with hover (`highlighted || hovered`). Setting it marks the button
  visually emphasized — note the box itself never sets it; the
  `defaultStandardButton` mechanism's own highlighting is a Template-layer
  property and is untouched here.

## Usage

```qml
import QtQuick
import QtQuick.Templates as T
import Qool.Dialogs

DialogButtonBox {
    DialogButton { text: qsTr("Apply now") }
    DialogButton {
        text: qsTr("Delete everything")
        T.DialogButtonBox.buttonRole: T.DialogButtonBox.DestructiveRole
    }
}
```

**The attached property must be written with the `T.` qualifier**
(`T.DialogButtonBox.buttonRole`). The bare form
`DialogButtonBox.buttonRole` would resolve against this module's own
`DialogButtonBox` component instead of the Template type's C++ attached
property, and fail.

## Deliberate trims

- No `checked` visual — no Binding block on `checked` state (a plain
  `ToolButton` restyles when checked; this type does not).
- No cut-corner linkage — no `isFirst`/`Positioner` handling, so `cutSizeTL`
  is always 0: dialog button rows are not the toolbar strip where the first
  button carries the cut.
