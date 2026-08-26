# ColorPicker

A compact quick color picker: a solid swatch that reveals a full-saturation
hue × lightness gradient surface on hover, writing the picked color to a
single `color` property.

`ColorPicker` is a small (200×50 implicit) preview-and-pick item. In its
rest state it shows a solid swatch of `color` with a foreground-contrast
border. On hover (or while interacting) a full-saturation gradient surface
fades in — horizontal hue, vertical lightness — overlaid by a vertical
lightness gradient (white top → transparent middle → black bottom) that maps
the lightness from 1 (top) to 0 (bottom).

### Interaction

- **Picking**: press-drag (or press-and-hold) writes
  `color = Qt.hsla(hue, 1, lightness, 1)` — `hue` follows the mouse X from 0
  (left) to 1 (right); `lightness` follows the mouse Y from 1 (top) to 0
  (bottom). The pick is always on the full-saturation plane (s=1): a pick
  cannot produce a low-saturation or gray color. A plain click (no drag, no
  hold) does not pick.
- **Alt key**: holding the Alt key (while the item has focus — hover
  auto-grabs focus) hides the lightness gradient and fixes lightness at 0.5
  for a pure-hue pick; releasing restores lightness mode.
- **Focus**: the item grabs focus automatically on hover entry.

The gradient surface is drawn with the Shapes path
(`RectShape` + `RainbowGradient`), consistent with the module's
`RectShape`-based fix for the Qt `Rectangle` rounded-gradient shrink crash.

## Properties

- `color : color` (default: `"white"`)
  The current pick result — written as `Qt.hsla(hue, 1, lightness, 1)` on
  drag/hold picking. Bind it two-way to a `ColorAssistant` for
  synchronization. This replaces the former `currentColor` / `defaultColor`
  pair (removed in the `color`-property rewrite).

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch for the hue surface fade and the transition
  when not interacting.

## Signals

This type defines no additional signals.

## Methods

 This type defines no additional methods — the component exposes no `reset()`,
and has no double-click reset behavior (the double-click handler was removed).

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorPicker {
    width: 200
    height: 50
    color: assistant.color
    onColorChanged: assistant.color = color
}
```
