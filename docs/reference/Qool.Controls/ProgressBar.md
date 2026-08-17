# ProgressBar

A QoolUI-styled progress bar based on `QtQuick.Templates.ProgressBar`.

`ProgressBar` indicates the progress of an operation (`value`/`from`/`to`
official semantics; `value` defaults to `0.5`). Visually it is an
`OctagonCurvedShape` background track plus an octagonal progress fill whose
width follows `visualPosition`; the fill's alignment is controlled by
`horizontalAlignment` (default left). A decorative vertical-bars gradient
runs inside the fill (`highlightColor` → `alternateHighlightColor`).

- `cycleDuration` controls the animation periods (default twice
  `Style.movementDuration`).
- `radius` rounds the corners (default half the height).
- `settings` is a read-only `QoolBoxSettings` describing the track's border
  configuration for external consumers.

**Deliberate design — indeterminate motion is not gated by
`animationEnabled`:** the back-and-forth loop animation of the indeterminate
mode does not read `Style.animationEnabled`. Motion is the *functional
semantics* of the indeterminate mode (the mode expresses itself through
motion), not a decorative effect; the animation gate only affects decorative
effects (such as the vertical-bars gradient animation). A host that needs to
stop the loop in high-performance mode should take over the `indeterminate`
state itself rather than rely on the gate.

## Properties

- `cycleDuration : int` (default `Style.movementDuration * 2`)
  Period of the loop animations (indeterminate mode and the bars
  animation).

- `horizontalAlignment : int` (default `Qt.AlignLeft`)
  Alignment of the progress fill within the track: `Qt.AlignLeft`,
  `Qt.AlignRight`, or any other value centers the fill.

- `radius : real` (default `floor(height / 2)`)
  Corner radius of the track and the progress fill.

- `highlightColor : color` (default `Style.active.highlight`)
  Main color of the progress fill (the gradient's top color).

- `alternateHighlightColor : color` (default `Qt.alpha(highlightColor, 0.2)`)
  Secondary gradient color of the progress fill (20% opacity of
  `highlightColor`).

- `borderColor : color` (default `Style.active.mid`)
  Track border color (read by the `settings` object).

- `backgroundColor : color` (default `Style.active.dark`)
  Track fill color.

- `settings : QoolBoxSettings` (read-only)
  The track's border configuration (`borderWidth` =
  `Style.controlBorderWidth`, `borderColor` = `Style.mid`, `fillColor` =
  `backgroundColor`, all four corner cuts = `radius`), exposed so external
  code can read the border geometry.

Inherited from `T.ProgressBar`: `from`, `to`, `value` (default `0.5` here),
`indeterminate`, `visualPosition`, `visualFocus` and all other
`ProgressBar`/`Control` members. See the Qt documentation for the inherited
members.

## Signals

This type defines no additional signals (inherits all signals from
`T.ProgressBar`, notably `valueChanged` and `indeterminateChanged`).

## Methods

This type defines no additional methods (inherits all methods from
`T.ProgressBar`).

## Usage Example

```qml
import QtQuick
import Qool.Controls

ProgressBar {
    width: 300
    value: 0.7
}

// Indeterminate mode: the loop motion is the mode's functional semantics
// and is NOT gated by Style.animationEnabled.
ProgressBar {
    width: 300
    indeterminate: true
}

// Right-aligned fill with a custom radius and colors.
ProgressBar {
    width: 300
    height: 12
    value: 0.3
    horizontalAlignment: Qt.AlignRight
    radius: 6
    highlightColor: Style.active.accent
}
```
