# ColorChannelEdit

A single color-channel value editor with a label — an `EditableText`
edit session bound to one `ColorAssistant` channel.

`ColorChannelEdit` presents one normalized channel (`channel`, e.g. hue /
saturation / lightness of a shared `ColorAssistant`) as a labeled,
editable value:

- **Display**: a label (`channelTag`) plus the channel value rendered by
  `ColorNameHQ.formatChannelNumberFloat` — three decimal digits without a
  leading zero (e.g. `.350`). The text is read live from the real channel
  through a `PropertyProxy` bridge (`channelNameF(channel)` — the channel
  name is a runtime string, so the proxy performs the dynamic lookup).
- **Edit**: clicking or focusing the value enters an `EditableText`
  session (select-all; typing replaces). Committing (Enter / focus loss)
  validates the input through a `RegularExpressionValidator` (no leading
  zero required; empty, invalid and scientific input rejected), parses it
  with `parseChannelValue`, writes `value`, and normalizes the display. A
  rejected input leaves the data untouched and the display falls back to
  the real channel value.
- **Sync**: `value` is the component's source — the only write entry
  (edit commit or host code). It is unconditionally two-way synchronized
  with the assistant's channel; the display follows the real channel
  directly, independent of the editor text.

### Numeric convention

`parseChannelValue(s)` parses with `parseFloat` and applies the
repository's channel-input convention (shared with
`NumInput.parseChannelValue`):

- `x > 1` is interpreted as `x / 1000` — typing `350` means `0.35`
  (integers 0..1000 represent 0..1 ratios; 1000 means 1.0).
- The result is clamped to `[0, 1]`; `NaN` passes through (empty / invalid
  input is rejected by the validator first).

## Properties

- `value : real`
  The real data — the component's source and the only write entry. Edit
  commits and host assignments write here; the value is mirrored to the
  assistant's channel and back.

- `channel : int` (default: `ColorNameHQ.HSLHue`)
  The channel to edit on `colorAssistant` — one of the `ColorNameHQ`
  channel constants (e.g. `HSLLightness`, `HSVSaturation`). The label
  follows it (`channelTag`); the display / edit address is derived
  dynamically (`channelNameF`).

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is edited.

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`).

Inherited from `Control`: `font`, `padding`, `enabled`, `focus`,
`implicitWidth` / `implicitHeight` and all other `Control` members. See
the Qt documentation for the inherited members.

## Signals

This component defines no additional signals.

## Methods

- `real parseChannelValue(string s)`
  Parses an input string into a normalized channel value: `parseFloat`,
  `x > 1` → `x / 1000`, clamped to `[0, 1]`; `NaN` passes through.

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
    ColorChannelEdit {
        colorAssistant: ca
        channel: ColorNameHQ.HSLLightness
    }
    ColorChannelEdit {
        colorAssistant: ca
        channel: ColorNameHQ.HSLSaturation
    }
}
```

Editing the lightness to `350` writes `0.35` into `ca`'s lightness
channel; the display normalizes to `.350`.
