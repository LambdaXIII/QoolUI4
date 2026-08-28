# ClickableText

A text button (`AbstractButton` semantics) with an animated underline bar.

`ClickableText` is an `AbstractButton`-based clickable text: standard
button interaction (click / `clicked()`, `checkable`/`checked`, `enabled`,
`hovered`) with the text as the content. An underline bar below the text
gives the state feedback: it fills in on hover/press, fills the whole item
height when checked, and follows the `AbstractButton` state colors. It is
used as a navigation/tab-like item and as the `ActionInstantiator`
delegate.

## Properties

- `checkedText : string` (default: `text`)
  The text shown when `checkable && checked` (the checked state's label).
  Defaults to `text` — set it to swap the label on check.

- `showBar : bool` (default `true`)
  Whether the underline bar is visible. When `false` the bar is hidden and
  the content keeps no extra bar padding.

- `barSpacing : real` (default `2`), `barHeight : real` (default `2`)
  The gap between the text and the bar, and the bar's resting height.

- `horizontalAlignment : int`, `verticalAlignment : int`, `elide : int`
  Text alignment and elide mode, forwarded to the content text.

Inherited from `T.AbstractButton`: `text`, `checkable`, `checked`, `down`,
`pressed`, `hovered`, `enabled`, `action`, `clicked()`, `toggled()` and all
other `AbstractButton`/`Control` members. See the Qt documentation for the
inherited members. `font.pixelSize` defaults to `Style.controlTextSize`.

## Signals

This type defines no additional signals (inherits all signals from
`T.AbstractButton`, notably `clicked()` and `toggled()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.AbstractButton`).

## Visual states

- Text color: `down` → `Style.highlight`; `checked` →
  `Style.highlightedText`; otherwise `Style.buttonText`.
- Bar: `color` = `Style.highlight` when `checked || down` else
  `Style.buttonText`; `percentage` animates to 1 when `down || hovered ||
  checked` (0 when disabled); when checked the bar fills the whole item
  height (its height animates from `barHeight` to the content height). The
  animations are gated by `Style.animationEnabled`.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

// Navigation tab style: checkable, group-exclusive.
ClickableText {
    text: "Overview"
    checkable: true
    ButtonGroup.group: navGroup
}

// Checked label swap.
ClickableText {
    text: qsTr("Writable")
    checkedText: qsTr("Read-only")
    checkable: true
}
```
