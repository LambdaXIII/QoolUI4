# ColorQuickPicker

A quick HSV gradient color picker: a full-saturation HSV surface revealed
on hover, with drag/press-and-hold picking and double-click reset.

`ColorQuickPicker` shows a solid `currentColor` with a foreground-contrast
border by default (not hovered). On hover, a full-saturation HSV gradient
surface (horizontal hue × vertical lightness) fades in and the border
becomes `currentColor`.

### Interaction

- **Hover**: the HSV gradient fades in; the border becomes the current
  color.
- **Picking**: press-drag (or press-and-hold) sets
  `currentColor = Qt.hsla(hue, 1, lightness, 1)` — `hue` follows the
  mouse X from 0 (left) to 1 (right), `lightness` follows the mouse Y
  from 1 (top) to 0 (bottom). A plain click (no drag, no hold) does not
  pick.
- **Double-click**: resets `currentColor = defaultColor`.
- **Keyboard**: the component grabs focus automatically when hover is
  entered; the Alt behavior below then applies.

### Alt key behavior

While **Alt is held**:

- the lightness gradient (`valueBox`) is hidden — only the pure hue
  gradient remains;
- picking fixes `lightness` at 0.5 (mid lightness) instead of following
  the mouse Y — the result is a "pure hue" color.

Alt is a temporary switch: it must stay held while picking; releasing it
restores lightness mode. Key events are handled through the `Keys`
attached property, which requires the component to own active focus
(grabbed automatically on hover enter); if the host takes the focus, the
Alt switch does not work.

Picking always happens on the full-saturation (s = 1) surface — this
component cannot pick low-saturation or gray colors.

### Defaults

`currentColor` defaults to `defaultColor` (`"white"`), so the component is
self-consistent standalone. The double-click reset target is
`defaultColor`.

## Properties

- `currentColor : color` (default: `defaultColor`)
  The current pick result. Written as `Qt.hsla(hue, 1, lightness, 1)` on
  drag/hold picking; double-click or `reset()` writes back
  `defaultColor`. Bind it two-way to a `ColorAssistant` for
  synchronization.

- `defaultColor : color` (default: `"white"`)
  The double-click reset target.

- `animationEnabled : bool` (default: inherited from the parent, falling
  back to `Style.animationEnabled`)
  The animation master switch. When false, the gradient show/hide and
  border color change complete instantly.

## Signals

This type defines no additional signals.

## Methods

- `void reset()`
  Resets `currentColor` to `defaultColor` (equivalent to a double-click).

## Usage Example

```qml
import QtQuick
import Qool.Color

ColorQuickPicker {
    id: picker
    width: 200
    height: 50
    currentColor: assistant.color
    defaultColor: "white"
    onCurrentColorChanged: assistant.color = currentColor
}
```
