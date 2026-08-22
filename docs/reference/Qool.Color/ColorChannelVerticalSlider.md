# ColorChannelVerticalSlider

A vertical single color-channel slider bound to one `ColorAssistant` channel —
a `QtQuick.Templates.Slider` peer whose track is a fill bar (the migrated
legacy `_private` `ChannelBar` visual) and whose handle is transparent.

`ColorChannelVerticalSlider` brings the vertical channel family of
`RGBPanel` / `CMYKPanel` (legacy `ChannelBar` + `ChannelSlider` + per-channel
variants) to a public component form: the fill-bar track visual is preserved
(rounded corners, fill from the bottom, identity-color gradient, 1 s
just-moved border highlight, no hover state, no visible handle) while the
interaction moves to the `T.Slider` template (drag, click-to-jump, keyboard
stepping, RTL). It is a **high-customization component** (ADR-0018, the third
instance after `ColorChannelSlider` and `HSVWheel`): the channel visuals
(fill bar, rainbow, border, just-moved highlight) are internalized as
component semantics and expose no variant-style appearance interface; the
template-level `background` / `handle` delegates remain the only plug-points
and can be replaced wholesale. The interaction contract is trimmed: there is
no `defaultValue`, `reset`, or double-click reset.

- **Channel addressing**: one generic `channel: int` (any `ColorNameHQ`
  channel constant) — no per-channel variant files. The track fill follows
  the channel: non-hue channels use a fixed identity color (data literals
  preserved verbatim from the legacy variants: Red `red`, Green `green`
  (`#008000`), Blue `blue`, Alpha `grey`, Black `darkgrey`, Value/Lightness
  `white`, Saturation = the principled result color after changing the
  channel); hue channels show a 11-stop rainbow background (hue 0 at the
  bottom → hue 1 at the top, α 0.2) whose stop colors **follow the current
  color state** — `hsva(p, hsvSaturationF, hsvValueF)` for `HSVHue` and
  `hsla(p, hslSaturationF, hslLightnessF)` for `HSLHue` — like the
  `HSVWheel` / `HSLBox` backgrounds (what-you-see-is-what-you-get: a dark
  current color darkens the rainbow, a gray one grays it). This differs
  deliberately from the horizontal `ColorChannelSlider` track (fixed
  `hsva(p, 1, 1, 1)` rainbow).
- **Fill = track sample color**: the fill color is the track's sample color
  at the fill's top edge — the principled color a position would show
  (semantics aligned with `Qool.Controls.Slider`'s `ColorMapper.colorAt`):
  for hue channels `hsva(value, hsvSaturationF, hsvValueF)` /
  `hsla(value, hslSaturationF, hslLightnessF)`; for non-hue channels it
  degenerates to the identity color. The fill and the rainbow share the same
  smoothed value source, so the fill edge and the background stay seamless
  while animating. Fill color is a pure binding (zero animation); only the
  fill height animates (`animationEnabled && !pressed` — drag follows
  instantly, non-interactive changes smooth).
- **Sync**: `value` is unconditionally two-way synchronized with the
  assistant's channel through a `PropertyProxy` bridge
  (`channelNameF(channel)` — the channel name is a runtime string, so the
  proxy performs the dynamic lookup). Dragging writes the channel; external
  color changes (linked controls, programmatic writes) move the fill back;
  `onCompleted` seeds `value` from the real channel. Convergence is guarded
  by same-value checks on both sides — no interaction gate is needed.
- **Behavior**: `value` is clamped to `[0, 1]`; dragging hue on an
  achromatic color first bumps the corresponding saturation to 0.001 so the
  hue write has a visible effect (legacy UX contract); the initial `value`
  is 1 (hue 1 ≡ 0 cyclically — no side effect before seeding).
- **Handle**: the default handle is a transparent `side × side` `Item`
  (25 × 25 at the default size) — no visible visual, no hover feedback, no
  cursor shape; all interaction is carried by the template's control layer
  (dragging on the bar, click-to-jump elsewhere). Replacing `handle` with
  any `Item` remains the template plug-point.
- **Orientation**: `orientation` defaults to `Qt.Vertical`. The fill-bar
  visual is vertically oriented — the "fill from the bottom" semantics are
  undefined in a horizontal form, so host applications should keep the
  vertical orientation.

## Properties

- `value : real`
  The slider value — the component's write entry (drag or host assignment),
  clamped to `[0, 1]`. Mirrored to the assistant's channel and back;
  seeding and external color changes settle it to the channel's real stored
  value (a `~1e-5` quantization settle is expected and one-shot).

- `channel : int` (default: `ColorNameHQ.HSLHue`)
  The channel to control on `colorAssistant` — one of the `ColorNameHQ`
  channel constants (e.g. `HSVHue`, `HSVSaturation`, `Red`, `Alpha`). The
  track fill and the sync address derive from it.

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is controlled.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`). When off, the fill height, fill color and
  border changes jump instantly.

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
        channel: ColorNameHQ.HSVHue
        height: 150
    }
    ColorChannelVerticalSlider {
        colorAssistant: ca
        channel: ColorNameHQ.HSVSaturation
        height: 150
    }
    ColorChannelVerticalSlider {
        colorAssistant: ca
        channel: ColorNameHQ.HSVValue
        height: 150
    }
}
```

Dragging any slider writes its channel into `ca`; changing `ca`'s color from
elsewhere (a linked editor, another picker) moves all sliders back to the
new channel values. On the hue slider, the rainbow background and the fill
track the current saturation/value of `ca` — a gray current color grays the
rainbow, and dragging the hue on a gray color still produces a visible
change (the saturation is bumped first).
