# Button

A QoolUI-styled push button based on `QtQuick.Templates.AbstractButton`.

`Button` provides the standard `AbstractButton` API (`text`, `pressed`,
`checked`, `checkable`, `enabled`, `hovered`, `clicked()`, etc.) with a QoolUI
visual: an octagonal background box whose fill, border and corner cuts are
controlled by `backgroundSettings`, a `BasicButtonText` content item, and the
standard Qool interaction overlay layers (pressed / highlight / locked
covers).

- When `checked` is `true`, the background switches to the theme highlight
  color (`Style.highlight`) and both the text and the border switch to
  `Style.highlightedText`.
- `highlighted` is a read-only convenience state (`enabled && hovered`); it
  drives the highlight overlay layer, which is a soft tint over the whole
  button while hovered.
- `flat` is a deliberately designed mode: the background becomes fully
  transparent (no border, no fill — the frame opacity drops to 0), keeping
  only the text and the interaction feedback layers (pressed/hovered
  highlight covers). This matches the semantics of `flat` in Qt Quick
  Controls (remove the themed background, keep text feedback on hover), and
  differs deliberately from `QoolButton` (which keeps its outline): `flat`
  means "no background at all" and is meant for toolbar / navigation-bar
  embedding.

The internal padding is derived from `backgroundSettings.borderWidth` and the
corner cut sizes (each side leaves room for half the larger adjacent cut), so
the text never collides with the cut corners.

## Properties

- `backgroundSettings : QoolBoxSettings`
  Unified appearance configuration for the background fill, border and the
  four corner cuts. Defaults to a `QoolBoxSettings` with all four
  `cutSizeTL/TR/BL/BR` = `Style.buttonCutSize`, `fillColor` =
  `Style.button`, `borderColor` = `Style.controlBorderColor`, `borderWidth` =
  `Style.controlBorderWidth` and `curved: true`. The background `Rectangle`
  maps the cuts, fill and border directly from this object.

- `highlighted : bool` (read-only)
  Convenience hover state: `enabled && hovered`. Drives the
  `ControlHighlightCover` overlay (opacity 1 when highlighted, 0 otherwise).

- `flat : bool` (default `false`)
  When `true`, the button background is fully transparent: `frameOpacity`
  becomes 0, so no border and no fill are drawn; only the text and the
  interaction feedback layers (pressed/hovered covers) remain. Intended for
  embedding into toolbars and navigation bars. The background's `opacity` is
  bound to `frameOpacity` while it is below 1 (with a `BasicNumberBehavior`
  gated by `Style.animationEnabled`).

Inherited from `T.AbstractButton`: `text`, `checked`, `checkable`, `down`,
`pressed`, `hovered`, `enabled`, `font`, `icon`, `autoRepeat`, `clicked()`,
`toggled()` and all other `AbstractButton`/`Control` members. See the Qt
documentation for the inherited members. `font.pixelSize` defaults to
`Style.controlTextSize`, and `hoverEnabled` is `true`.

## Signals

This type defines no additional signals (inherits all signals from
`T.AbstractButton`, notably `clicked()` and `toggled()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.AbstractButton`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

Button {
    text: "Save"
    onClicked: save()
}

// Toolbar-style: no background at all, only text + hover tint.
Button {
    text: "New"
    flat: true
    onClicked: createNew()
}

// Checkable button with the Qool highlight state.
Button {
    text: "Bold"
    checkable: true
    checked: textBold
    onToggled: textBold = checked
}
```
