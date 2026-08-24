# ColorChannelControl

A single color-channel control — a labeled numeric edit plus a drag track
stacked in one of two layouts selected by `orientation`: horizontal
(default) is a `ColorChannelEdit` above a `ColorChannelSlider` at equal
width, restoring the legacy `_private` `ColorSlider` single-control form;
vertical is a `ColorChannelVerticalSlider` above a vertical
`ColorChannelEdit` with `tagOnTop` (the value box sits next to the slider,
the short label at the bottom).

`ColorChannelControl` bundles the properties the two children share
(`channel`, `colorAssistant`, `animationEnabled`, `value`, `readOnly`) on
one `Control`, so a host configures one component instead of pairing an edit
and a slider per channel.

- **Bundling invariant**: `colorAssistant` is a **single shared instance**
  declared by the control and forwarded to both children. The edit and the
  slider always act on the same channel; the bundled `value` converges with
  both through this one assistant. If the children fell back to their own
  default assistants the bundle would split — the shared instance is what
  keeps it closed.
- **Sync**: `value` is the control's **own third projection** — a
  `PropertyProxy` bridge (`channelNameF(channel)`) synchronizing
  bidirectionally with the assistant's channel, seeded from the real channel
  value in `onCompleted`. It is not aliased to either child's `value`;
  writes flow into the shared assistant and changes made by either child
  read back into it, so all three converge on the same value.
- **Pure encapsulation**: no `edit` / `slider` child aliases are exposed.
  Pluggability lives in the children themselves (`ColorChannelEdit`'s
  `displayItem`, the sliders' template `background` / `handle`).
- **Read-only editing**: `readOnly` forwards through the edit child to the
  internal editor — no edit session starts on click/focus. The slider stays
  fully draggable, so a read-only row still adjusts the channel.

## Properties

- `animationEnabled : bool`
  Animation switch (inherited up the parent chain — defaults to
  `Style.animationEnabled`). Declared first (repository convention) and
  forwarded **explicitly** to both children — a child's `parent` is the
  content layout, not the control, so the parent-chain lookup alone cannot
  reach it.

- `channel : int` (default: `ColorNameHQ.HSLHue`)
  The channel to control on `colorAssistant` — one of the `ColorNameHQ`
  channel constants (e.g. `HSVHue`, `HSVSaturation`, `Red`, `Alpha`).
  Forwarded to both children.

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {
  color: Style.accent }`)
  The shared color object whose channel is controlled — a **single shared
  instance** forwarded to both children (bundling invariant, see above).

- `value : real`
  The channel value — the control's own third projection. Writing it
  updates the assistant's channel; changes from the assistant (linked
  controls, programmatic writes, either child) read back into it. Seeded
  from the real channel value on completion; `NaN` is never written.
  Achromatic hue (`-1`) is passed through as-is — the children's out-of-range
  handling differences (the edit shows the real source, the slider guards it)
  are existing child behavior the control does not reconcile.

- `readOnly : bool` (default: `false`)
  Locks the numeric edit (forwarded to the internal editor — no edit
  session starts). The slider and the value chain remain fully live.

- `orientation : int` (default: `Qt.Horizontal`)
  Layout direction (`Qt.Horizontal` / `Qt.Vertical`). Horizontal: the edit
  row above the slider, both rows at equal width. Vertical: the vertical
  slider above a vertical edit row with `tagOnTop` (value box next to the
  slider, short label at the bottom). Switching rebuilds the content
  layout; the shared assistant and the value chain are unaffected.

- `horizontal : bool` (read-only) / `vertical : bool` (read-only)
  Derived from `orientation`.

Inherited from `Control`: padding, insets, `enabled`, `focus`, `visible`,
`z`, and all other `Control` members. See the Qt documentation for the
inherited members.

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
    spacing: 4
    ColorChannelControl {
        colorAssistant: ca
        channel: ColorNameHQ.HSVHue
    }
    ColorChannelControl {
        colorAssistant: ca
        channel: ColorNameHQ.HSVSaturation
    }
    ColorChannelControl {
        colorAssistant: ca
        channel: ColorNameHQ.HSVValue
        readOnly: true    // numeric read-only; drag still adjusts
    }
}

// Vertical form — a tall fill-bar slider with the flipped edit below it
// (tagOnTop: value box next to the slider, short label at the bottom):
ColorChannelControl {
    colorAssistant: ca
    channel: ColorNameHQ.HSVHue
    orientation: Qt.Vertical
}
```

Editing a value or dragging a row writes its channel into `ca`; changing
`ca`'s color from elsewhere (a linked picker, another editor) moves all rows
back to the new channel values — the shared assistant keeps every row's edit
and slider in step.
