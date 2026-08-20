# Dial

A circular dial knob (the v3 Color dial visual family, generalized): a
circular background with a `Style.buttonText` border, a capsule pointer
handle, and a three-stop gradient arc (`DialRangeArc`) that appears while
pressed.

`Dial` provides the standard `T.Dial` API (`from`, `to`, `value`,
`stepSize`, `wrap`, `startAngle`, `endAngle`, `inputMode`, ...). Interaction
is the template default (circular drag, relative horizontal/vertical drag,
arrow-key stepping — official behavior; the interface is compatible with
`QtQuick.Templates.Dial`). The handle is a rounded capsule whose rotation
follows `angle`; while pressed (mouse press **or** key held — the template
semantic, see Qt docs for `pressed`), the handle recolors to the gradient
sample at the current position and the gradient arc (`DialRangeArc`)
appears around the circle. The sample follows `position` in real time via a
three-stop `ColorMapper` (`lowColor` → `midColor` → `highColor` around the
range).

- **Background** — a `Rectangle` circle in the `background`
  (`Style.controlBackgroundColor` fill, `Style.buttonText` border,
  `Style.controlBorderWidth` width, radius = half the size), hosting the
  `DialRangeArc`. The background size is `Math.max(35, min(width, height))`
  — it never shrinks below 35 px and never exceeds the control, centered.
- **Handle** — the default `handle` is a rounded capsule (`width =
  max(4, min(w, h) × 0.05)`, `height = max(bg.width × 0.3, 4)`), offset
  toward the rim and rotated by `angle` around its center. Replacing
  `handle`/`background` with any `Item` is behavior plugging (template
  delegate contract) — the positioning binding is the host's responsibility
  (the template never positions delegates).

## Properties

- `highColor : color` (default `Style.red`)
  The gradient sample color at the range's maximum (`position` 1) — the
  arc's `to` stop and the handle's color when the value sits at the top of
  the range.
- `midColor : color` (default `Style.yellow`)
  The gradient sample color at the range's middle (`position` 0.5).
- `lowColor : color` (default `Style.green`)
  The gradient sample color at the range's minimum (`position` 0).
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates
  the focus-highlight border transition; when off, the switch is instant
  instead of animated.
- `focusBorderColor : color` (default `Style.highlight`)
  The focus-highlight border color — while the control holds keyboard
  focus (`visualFocus`, see "Interaction feedback") the default background
  border switches to this color and reverts to `Style.buttonText` on
  losing focus. Set a transparent color to disable the behavior. It only
  affects the default `background`; replacing `background` drops the
  behavior.

Inherited from `T.Dial`: `from`, `to`, `value`, `stepSize`, `wrap`,
`position`, `angle`, `startAngle`, `endAngle`, `inputMode`, `live`,
`pressed`, `hovered`, `increase()`, `decrease()`, `moved()`, `wrapped()`,
and all other `Dial`/`Control` members. See the Qt documentation for the
inherited members. The default implicit size is `50 × 50` (the
`background`'s explicit implicit size via the standard template formula).

## Signals

This type defines no additional signals (inherits all signals from
`T.Dial`, notably `moved()` and `wrapped(Dial.WrapDirection)`).

## Methods

This type defines no additional methods (inherits all methods from
`T.Dial`, notably `increase()` and `decrease()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

Dial {
    width: 120
    height: 120
    from: 0
    to: 100
    value: 50
    onValueChanged: console.log("value:", value)
}

// Custom gradient stops: recolor the arc and the pressed handle sample.
Dial {
    width: 120
    height: 120
    lowColor: Style.active.base
    midColor: Style.active.accent
    highColor: Style.positive
}

// Custom angles: limit the travel arc (Qt 6.6+).
Dial {
    width: 120
    height: 120
    startAngle: -90
    endAngle: 90
}

// Focus highlight opt-out: transparent focusBorderColor disables it.
Dial {
    width: 120
    height: 120
    focusBorderColor: "transparent"
}
```

## Interaction feedback

- Press feedback: while `pressed` (mouse press **or** arrow key held —
  the template sets `pressed` for both, see the Qt docs), the handle
  recolors to the gradient sample at the current position (`valueColor`,
  driven by `position`/`highColor`/`midColor`/`lowColor` changes) and the
  `DialRangeArc` gradient arc appears around the circle; on release both
  revert. The arc is purely a pressed-state indicator (opacity 0
  otherwise) — there is no hover feedback.
- Keyboard: arrow keys step `value` by `stepSize` (or 0.1 when unset);
  Home/End jump to `from`/`to`; `wrap: true` wraps around
  (`wrapped()` fires). Stepping also drives the press feedback above.
- Keyboard focus highlight: while the dial holds keyboard focus
  (`visualFocus` — Qt's standard semantic, `true` only when focus was
  acquired through keyboard navigation, i.e. Tab/Backtab/shortcut; mouse,
  programmatic and window-switch focus do not light it), the default
  background border switches to `focusBorderColor` (default
  `Style.highlight`) and reverts to `Style.buttonText` on losing focus,
  animated under the `animationEnabled` gate. Focusability stays at the
  Qt default — the control does not set `activeFocusOnTab`; the mechanism
  is ready to use once the host enables focus the Qt-standard way
  (`activeFocusOnTab` or `forceActiveFocus`). The highlight lives inside
  the default `background` only — replacing `background` removes it.
  Note: `Style.highlight` may have low contrast against light track
  colors — set `focusBorderColor` for a contrast-safe color.
