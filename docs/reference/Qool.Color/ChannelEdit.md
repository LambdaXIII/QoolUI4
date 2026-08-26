# ChannelEdit

A single color-channel value editor with a label — an `EditableText`
edit session bound to one `ColorAssistant` channel.

`ChannelEdit` presents one normalized channel (`channel`, e.g. hue /
saturation / lightness of a shared `ColorAssistant`) as a labeled,
editable value:

- **Display**: a label (`channelTag`) plus the channel value rendered by
  `ColorHQ.formatChannelNumberFloat` — three decimal digits without a
  leading zero (e.g. `.350`). The text is read live from the real channel
  through a `PropertyProxy` bridge (`channelNameF(channel)` — the channel
  name is a runtime string, so the proxy performs the dynamic lookup).
- **Edit**: clicking or focusing the value enters an `EditableText`
  session (select-all; typing replaces). Committing (Enter / focus loss)
  validates the input through a `RegularExpressionValidator` (no leading
  zero required; empty, invalid and scientific input rejected), parses it
  with `parseChannelNumberFloat`, writes `value`, and normalizes the display. A
  rejected input leaves the data untouched and the display falls back to
  the real channel value.
- **Sync**: `value` is the component's source — the only write entry
  (edit commit or host code). It is unconditionally two-way synchronized
  with the assistant's channel; the display follows the real channel
  directly, independent of the editor text.
- **Layout**: horizontal (default) shows the long label (`channelTag`)
  left-aligned with the value at the right; `orientation: Qt.Vertical`
  shows the short label (`channelTagShort`) above the value, both
  horizontally centered. Two independent signals drive the remaining
  layout variants. `mirrored` (the built-in read-only Control property,
  driven by `LayoutMirroring.enabled`) is the **environment** signal: it
  swaps horizontal positions only — the value moves to the left edge and
  the label to the right (the gap is kept). `tagOnTop` is an **explicit**
  property with vertical meaning only: it stacks the value above the
  short label. Text content, direction and alignment are unaffected.

### Numeric convention

The numeric text is the `ColorHQ` static pair
`formatChannelNumberFloat` / `parseChannelNumberFloat`, deliberately
restricted:

- **Format** produces exactly four outputs: `"0"`, `"1"`, `".xxx"` (three
  decimal digits without a leading zero, e.g. `.350`), `"NaN"`. Values
  rounding to 1000 (≥ 0.9995) collapse to `"1"`.
- **Parse** cleans the input (keeps digits and the *first* decimal point
  only), prepends a decimal point when none is present — integers are read
  as pure decimals, so typing `350` means `.350` = 0.35, matching the
  display form — then parses the number; failure (empty / no digits)
  yields `NaN`.

The display and the saved form are therefore the same `.xxx` shape and
round-trip (except `"1"`, which parses back as `.1` = 0.1 — an accepted
consequence of the leading-dot convention).

## Properties

- `value : real`
  The real data — the component's source and the only write entry. Edit
  commits and host assignments write here; the value is mirrored to the
  assistant's channel and back.

- `channel : int` (default: `ColorHQ.HSLHue`)
  The channel to edit on `colorAssistant` — one of the `ColorHQ`
  channel constants (e.g. `HSLLightness`, `HSVSaturation`). The label
  follows it (`channelTag`); the display / edit address is derived
  dynamically (`channelNameF`).

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is edited.

- `readOnly : bool` (default: `false`)
  Forwards to the internal `EditableText.readOnly` — no edit session
  starts (click / focus idle). `ChannelControl` forwards its shell
  `readOnly` through this property; hosts may set it directly.

- `orientation : int` (default: `Qt.Horizontal`)
  Layout direction. `Qt.Horizontal` — the default — lays the label and
  the value side by side (long label `channelTag` left, value right);
  `Qt.Vertical` stacks the short label `channelTagShort` above the value,
  both horizontally centered.

- `horizontal : bool` (read-only)
  `true` when `orientation === Qt.Horizontal` — the horizontal layout is
  active.

- `vertical : bool` (read-only)
  `true` when `orientation === Qt.Vertical` — the vertical layout is
  active.

- `tagOnTop : bool` (default: `false`)
  Vertical stack order, meaningful only when `orientation` is
  `Qt.Vertical`. `false` — the short label sits above the value; `true` —
  the value stacks above the label (the form used by
  `ChannelControl`'s vertical column, where the value hugs the
  slider). Deliberately an explicit property rather than driven by the
  environment: vertical stacking is pure layout intent and must not flip
  when the host enables layout mirroring.

- `mirrored : bool` (read-only, inherited from `Control`)
  The **environment** mirror signal — swaps horizontal positions only:
  the label sits flush right, the value flush left (5px gap preserved).
  Driven by `LayoutMirroring.enabled`; hosts do not assign it directly.
  It does not affect the vertical stack order (see `tagOnTop`).

Inherited from `Control`: `font`, `padding`, `enabled`, `focus`,
`implicitWidth` / `implicitHeight` and all other `Control` members. See
the Qt documentation for the inherited members.

## Signals

This component defines no additional signals.

## Methods

This component defines no additional methods. Parsing is provided by the
shared implementation `ColorHQ.parseChannelNumberFloat()` (see
"Numeric convention").

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
    ChannelEdit {
        colorAssistant: ca
        channel: ColorHQ.HSLLightness
    }
    ChannelEdit {
        colorAssistant: ca
        channel: ColorHQ.HSLSaturation
    }
    ChannelEdit {
        colorAssistant: ca
        channel: ColorHQ.HSLHue
        orientation: Qt.Vertical
    }
}
```

Editing the lightness to `350` writes `0.35` into `ca`'s lightness
channel; the display normalizes to `.350`.
