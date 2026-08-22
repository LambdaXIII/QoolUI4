# ColorChannelSlider

A single color-channel slider bound to one `ColorAssistant` channel — a
`QtQuick.Templates.Slider` peer whose track shows the channel's gradient and
whose handle shows the current solid color.

`ColorChannelSlider` is the drag part of the legacy `_private` `ColorSlider`
split: `ColorChannelEdit` owns the labeled numeric edit, this component owns
the track + handle + drag interaction. It is a **high-customization
component** (ADR-0013): the channel visuals (gradient, cursor, stroke) are
internalized as component semantics and expose no variant-style appearance
interface (`fillGradient` / `strokeColor` aliases are deliberately absent);
the template-level `background` / `handle` delegates remain the only
plug-points and can be replaced wholesale.

- **Channel addressing**: one generic `channel: int` (any `ColorNameHQ`
  channel constant) — no per-channel variant files. The track gradient
  follows the channel (Hue rainbow, RGB black → pure color, Value/Lightness
  black → white, CMYK white → pure color, Alpha transparent → current solid,
  Saturation gray → pure hue at current brightness), and the handle shows
  `colorAssistant.solidColor`.
- **Sync**: `value` is unconditionally two-way synchronized with the
  assistant's channel through a `PropertyProxy` bridge
  (`channelNameF(channel)` — the channel name is a runtime string, so the
  proxy performs the dynamic lookup). Dragging writes the channel; external
  color changes (linked controls, programmatic writes) move the handle back;
  `onCompleted` seeds `value` from the real channel. Convergence is guarded
  by same-value checks on both sides — no interaction gate is needed.
- **Behavior**: `value` is clamped to `[0, 1]`; dragging hue on an
  achromatic color first bumps the corresponding saturation to 0.001 so the
  hue write has a visible effect (legacy UX contract); there is no
  `defaultValue`, `reset`, or double-click reset; the initial `value` is 1
  (hue 1 ≡ 0 cyclically — no side effect before seeding).
- **Handle**: the default handle is a `CrystalCursor` inline wiring — the
  shared delayed-scale base component (`Qool.Controls.Components`, ADR-0016):
  a `Crystal` diamond showing `colorAssistant.solidColor`, positioned by
  `displayValue` (a smoothed intermediate layer: the drag follows instantly,
  external changes animate), expanded by the three-state feedback
  (hover / pressed / value-change latch) under the `animationEnabled` gate.
  Replacing `handle` with any `Item` remains the template plug-point.

## Properties

- `value : real`
  The slider value — the component's write entry (drag or host assignment),
  clamped to `[0, 1]`. Mirrored to the assistant's channel and back;
  seeding and external color changes settle it to the channel's real stored
  value (a `~1e-5` quantization settle is expected and one-shot).

- `channel : int` (default: `ColorNameHQ.HSLHue`)
  The channel to control on `colorAssistant` — one of the `ColorNameHQ`
  channel constants (e.g. `HSVHue`, `HSVSaturation`, `Red`, `Alpha`). The
  track gradient and the sync address derive from it.

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is controlled.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`). When off, the handle position, handle color and
  stroke changes jump instantly.

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
    ColorChannelSlider {
        colorAssistant: ca
        channel: ColorNameHQ.HSVHue
    }
    ColorChannelSlider {
        colorAssistant: ca
        channel: ColorNameHQ.HSVSaturation
    }
    ColorChannelSlider {
        colorAssistant: ca
        channel: ColorNameHQ.HSVValue
    }
}
```

Dragging any slider writes its channel into `ca`; changing `ca`'s color from
elsewhere (a linked editor, another picker) moves all sliders back to the
new channel values.
