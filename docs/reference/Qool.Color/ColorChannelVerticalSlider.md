# ColorChannelVerticalSlider

A vertical single color-channel slider bound to one `ColorAssistant` channel —
a `QtQuick.Templates.Slider` peer whose track is a fill bar and whose handle
is transparent.

`ColorChannelVerticalSlider` is the public form of the legacy vertical
channel bars of `RGBPanel` / `CMYKPanel` (the panels are now composed from
`ColorChannelControl` vertical columns): the fill-bar track visual is
preserved (rounded corners, fill from the bottom, identity-color gradient,
no hover state, no visible handle) while the interaction moves to the
`T.Slider` template (drag, click-to-jump, keyboard stepping, RTL). It is a
**high-customization component** (ADR-0018, the third instance after
`ColorChannelSlider` and `HSVWheel`): the channel visuals (fill bar, rainbow,
border) are internalized as component semantics and expose no variant-style
appearance interface; the template-level `background` / `handle` delegates
remain the only plug-points and can be replaced wholesale. The interaction
contract is trimmed: there is no `defaultValue`, `reset`, or double-click
reset.

- **Channel addressing**: one generic `channel: int` (any `ColorHQ`
  channel constant) — no per-channel variant files. Non-hue channels use the
  identity color from the shared lookup
  (`ColorHQ.channelColor` / C++ `ColorLiterals::channelColor`: Red/Blue/
  Cyan/Magenta/Yellow pure, Green `green` (#00ff00), Alpha gray, Black
  darkGray, Value/Lightness lightGray; Saturation = the principled result
  color after changing the channel). Hue channels show an 11-stop
  `RainbowGradient` background (hue 0 at the value-0 end → hue 1 at the
  value-1 end, `Qt.hsva(p, 1, 1, 0.25)`) — fixed full-brightness, **not**
  following the current color's saturation/value/lightness.
- **Fill = hue-normal color (hue) / identity color (non-hue)**: the fill
  gradient's main color is `pCtrl.channelColor` — for hue channels the
  **normal hue color** (`HSVHue` = `hsva(position, 1, 1, 1)`, `HSLHue` =
  `hsla(position, 1, .5, 1)`; fixed saturation, HSV value 1 / HSL lightness
  0.5 — only the position changes the hue, the current color's darkness does
  not darken the fill); for non-hue channels it degenerates to the identity
  color (the fill's secondary stop is `Qt.alpha(channelColor, 0.2)`). The
  alpha fade runs along the growth axis (leading edge strong → trailing
  edge faint, GradientStop positions 0.9 / 0.1). Fill color is a pure
  binding (zero animation); only the fill size animates
  (`seedDone && animationEnabled && !pressed` — drag follows instantly,
  non-interactive changes smooth).
- **Border**: the `RectShape` background border is the identity
  `pCtrl.channelColor` (fill `Qt.alpha(channelColor, 0.1)` tint) with a
  just-moved highlight: any `value` write (drag, numeric edit, external
  change) lights the border up to `Qt.lighter(channelColor, 1.4)` for a
  `Style.movementDuration * 2` window (internal `TimerLatch` — no exposed
  state), then it falls back.
- **Sync**: `value` is unconditionally two-way synchronized with the
  assistant's channel through a `PropertyProxy` bridge
  (`channelNameF(channel)` — the channel name is a runtime string, so the
  proxy performs the dynamic lookup). Dragging writes the channel; external
  color changes (linked controls, programmatic writes) move the fill back;
  `onCompleted` seeds `value` from the real channel (hue readings are
  always valid — anchors, ADR-0020 — so a gray assistant seeds `0`, not
  the old `1` default). Convergence is guarded by same-value checks on both
  sides — no interaction gate is needed.
- **Behavior**: `value` is clamped to `[0, 1]`
  (`ColorHQ.clampChannelRange`); hue writes go straight to the assistant,
  whose anchor model keeps them effective even on achromatic colors (the
  saturation-bump compensation patch is retired, ADR-0020); the initial
  `value` is 1 (hue 1 ≡ 0 cyclically — no side effect before seeding).
- **Handle**: the default handle is a transparent `side × side` `Item` — no
  visible visual, no hover feedback; an inner `NoButton` `MouseArea` supplies
  the direction cursor (`Qt.SizeHorCursor` / `Qt.SizeVerCursor`, gated by
  `enabled`) without intercepting the template drag. All interaction is
  carried by the template's control layer (dragging on the bar, click-to-jump
  elsewhere). Replacing `handle` with any `Item` remains the template
  plug-point.
- **Orientation**: `orientation` defaults to `Qt.Vertical`. Both orientations
  are supported: the fill bar is anchored at the value-0 end and grows toward
  the value-1 end — bottom-up when vertical, and from the value-0 end (left
  in LTR, right in RTL) when horizontal. The alpha fade runs along the growth
  axis, and the hue rainbow runs along the value direction (hue 0 at the
  value-0 end → hue 1 at the value-1 end). RTL mirrors the horizontal fill
  and rainbow (the value-0 end becomes the right); the vertical orientation
  is unaffected by RTL. `implicitWidth` / `implicitHeight` swap with
  orientation (25×150 vertical ↔ 150×25 horizontal).

## Properties

- `value : real`
  The slider value — the component's write entry (drag or host assignment),
  clamped to `[0, 1]`. Mirrored to the assistant's channel and back;
  seeding and external color changes settle it to the channel's real stored
  value (a `~1e-5` quantization settle is expected and one-shot).

- `channel : int` (default: `ColorHQ.HSLHue`)
  The channel to control on `colorAssistant` — one of the `ColorHQ`
  channel constants (e.g. `HSVHue`, `HSVSaturation`, `Red`, `Alpha`). The
  track fill and the sync address derive from it.

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is controlled.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`). When off, the fill size, fill color and border
  transitions jump instantly.

Inherited from `T.Slider`: `from`, `to`, `orientation`, `horizontal` /
`vertical`, `pressed`, `position`, `visualPosition`, `stepSize`, `snapMode`,
`live`, `moved()`, `increase()`, `decrease()`, `valueAt()`, and all `Control`
members (padding, insets, `enabled`, focus). See the Qt documentation for
the inherited members.

## Signals

This component defines no additional signals.

## Methods

This component defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: ca
    color: "red"
}

Row {
    spacing: 8
    ColorChannelVerticalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVHue
        height: 150
    }
    ColorChannelVerticalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVSaturation
        height: 150
    }
    ColorChannelVerticalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVValue
        height: 150
    }
}
```

Dragging any slider writes its channel into `ca`; changing `ca`'s color from
elsewhere (a linked editor, another picker) moves all sliders back to the
new channel values. On the hue slider the rainbow background stays
full-brightness (it does not follow the current saturation/value), and
dragging the hue on a gray color still produces a visible change (the
saturation is bumped first).
