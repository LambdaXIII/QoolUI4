# ChannelCrystalSlider

A single color-channel slider bound to one `ColorAssistant` channel — a
`QtQuick.Templates.Slider` peer whose track shows the channel's gradient and
whose handle shows the current solid color.

`ChannelCrystalSlider` is the drag part of the legacy `_private` `ColorSlider`
split: `ChannelEdit` owns the labeled numeric edit, this component owns
the track + handle + drag interaction. It is a **high-customization
component** (ADR-0013): the channel visuals (gradient, cursor, stroke) are
internalized as component semantics and expose no variant-style appearance
interface (`fillGradient` / `strokeColor` aliases are deliberately absent);
the template-level `background` / `handle` delegates remain the only
plug-points and can be replaced wholesale.

- **Channel addressing**: one generic `channel: int` (any `ColorHQ`
  channel constant) — no per-channel variant files. The track gradient
  follows the channel: hue channels use a fixed-brightness `RainbowGradient`
  (11 stops of `Qt.hsva(p, 1, 1, 0.25)`); non-hue channels use a static
  `ChannelGradient` — `toColor = ColorHQ.channelColor(channel)` (the
  shared C++ lookup: Red/Green/Blue/Cyan/Magenta/Yellow pure, Alpha gray,
  Value/Lightness lightGray, Black darkGray), `fromColor` `transparent` for
  RGB/Value/Lightness/Alpha, `black` for CMYK/Black, `white` otherwise. The
  handle shows `colorAssistant.solidColor`.
- **Sync**: `value` is unconditionally two-way synchronized with the
  assistant's channel through a `PropertyProxy` bridge
  (`channelNameF(channel)` — the channel name is a runtime string, so the
  proxy performs the dynamic lookup). Dragging writes the channel; external
  color changes (linked controls, programmatic writes) move the handle back;
  `onCompleted` seeds `value` from the real channel (hue readings are
  always valid — anchors, ADR-0020 — so a gray assistant seeds `0`, not
  the old `1` default). Convergence is guarded by same-value checks on both
  sides — no interaction gate is needed.
- **Behavior**: `value` is clamped to `[0, 1]`
  (`ColorHQ.clampChannelRange` — out-of-range only arrives from external
  programmatic writes); hue writes go straight to the assistant, whose
  anchor model keeps them effective even on achromatic colors (the
  saturation-bump compensation patch is retired, ADR-0020); there is no
  `defaultValue`, `reset`, or double-click reset; the initial `value` is 1
  (hue 1 ≡ 0 cyclically — no side effect before seeding).
- **Handle**: the default `handle` **is** the `CrystalCursor` itself (the
  root is the handle — same structure as `Qool.Controls.Slider`, ADR-0016):
  a `Crystal` diamond showing `colorAssistant.solidColor`, positioned by
  `displayValue` (a smoothed intermediate layer equal to `visualPosition`:
  the drag follows instantly, external changes animate), expanded by the
  three-state feedback (hover / pressed / value-change `TimerLatch`),
  `delta = pCtrl.shrinkSize`. The scale animation is always on (the resizer
  is hard-wired `animationEnabled: true`); the `animationEnabled` gate
  covers the position smoothing (`BasicNumberBehavior on displayValue`) and
  the color transitions. A `NoButton` `MouseArea` supplies the direction
  cursor (`Qt.SizeHorCursor` / `Qt.SizeVerCursor`), gated by `enabled`.
  Replacing `handle` with any `Item` remains the template plug-point.

## Properties

- `value : real`
  The slider value — the component's write entry (drag or host assignment),
  clamped to `[0, 1]`. Mirrored to the assistant's channel and back;
  seeding and external color changes settle it to the channel's real stored
  value (a `~1e-5` quantization settle is expected and one-shot).

- `channel : int` (default: `ColorHQ.HSLHue`)
  The channel to control on `colorAssistant` — one of the `ColorHQ`
  channel constants (e.g. `HSVHue`, `HSVSaturation`, `Red`, `Alpha`). The
  track gradient and the sync address derive from it.

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is controlled.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`). When off, the handle position smoothing, handle
  color and stroke transitions jump instantly. The handle **scale**
  expansion is not gated (the resizer is always animated).

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

Column {
    ChannelCrystalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVHue
    }
    ChannelCrystalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVSaturation
    }
    ChannelCrystalSlider {
        colorAssistant: ca
        channel: ColorHQ.HSVValue
    }
}
```

Dragging any slider writes its channel into `ca`; changing `ca`'s color from
elsewhere (a linked editor, another picker) moves all sliders back to the
new channel values.
