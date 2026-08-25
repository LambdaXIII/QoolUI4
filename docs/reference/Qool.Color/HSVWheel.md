# HSVWheel

A regenerable, public HSV two-dimensional color-picking surface: a hue wheel
that responds to the mouse to pick `hue`/`saturation` while `value` dims the
wheel, shaped as a single reusable `Qool.Color` component (v4, running on
this name). `HSVWheel` uses a **single-chain architecture** informed by its
older `_private` carrier, now promoted to a first-class component.

- **Single chain, no loop**: mouse events flow one way —
  `mouse → setValues() → data → position(hue,sat) → cursor`. The cursor is
  a *visualization of the value* (a pure derivation of `position`), not a
  separately draggable object, and the wheel reads the same data source
  independently. There is **no** "cursor ↔ value" two-way binding.
- **Atomic writes**: one mouse event writes `hue`/`saturation`/`value`
  together through the `hsvF` list setter (a single recompute round, one
  broadcast — no intermediate timing states).
- **Clamping for value validity** (not coordinate clamping): interactive
  writes keep `HSVSurface`'s `hueAt` / `saturationAt` / `check_point`
  clamps, plus a finiteness guard for the wheel center (`atan(0/0)` yields
  NaN — the write is skipped); the interface-level `hue`/`saturation`/
  `value` property writes normalize: `hue` wraps modulo into `[0,1)`
  (`-0.5 → 0.5`, `1.5 → 0.5` — always valid, achromaticity is judged by the
  assistant's saturation/value), `saturation`/`value` clamp to `[0,1]`.
  `position` stays a pure function — there is no hard boundary clamp inside
  it (value validity keeps the cursor in the circle).
- **Geometry relocation**: resizing the surface repositions the cursor via
  `onWidthChanged`/`onHeightChanged` handlers (the cursor is
  event-positioned, so a size change alone would leave it stale).
- **No `defaultValue`/`reset`, double-click undefined** — the interaction
  contract is trimmed to match `ColorChannelSlider`/`ColorChannelControl`.
- **No `defaultValue`/`reset`, double-click undefined** — the interaction
  contract is trimmed to match `ColorChannelSlider`/`ColorChannelControl`.
- The `_private` wheel surface (`HSVSurface`) stays private; the cursor is an
  **inline `CrystalCursor` + `CenterPlacer` wiring** inside the interacting
  area (same inline wiring as `HSLBox` — each surface hosts its own copy;
  there is no shared `_private` `ColorCursor` composite, ADR-0017). The
  public surface is the composition.

## Properties

- `animationEnabled : bool`
  Animation switch (inherited from the parent chain — defaults to
  `Style.animationEnabled`). Declared first (repository convention).

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {}`)
  The color object that is the single data source. The surface writes
  `hue`/`saturation` (on interaction) and reads them back; `value` drives
  the wheel's dim layer but is not written by user interaction. Default
  standalone instance makes `HSVWheel` usable on its own.

- `hue : real`
  The hue channel (0..1). Two-way: writing it updates the assistant's
  `hsvHueF`; a change from the assistant reads back. Out-of-range writes
  are normalized modulo into `[0,1)` (`-0.5 → 0.5`, `1.5 → 0.5`) — the
  hue reading is always valid (anchors, ADR-0020); on the gray axis
  (saturation 0) the written hue is remembered by the assistant anchor
  even though the color stays achromatic.

- `saturation : real`
  The saturation channel (0..1). Two-way; interface writes clamp to
  `[0,1]`.

- `value : real`
  The value (brightness) channel (0..1). Two-way; interface writes clamp to
  `[0,1]`. It drives the wheel's dim layer (darken alpha = `1 - value`)
  but is **not** written by surface interaction (hue/saturation only) —
  this value is external / linked and visualized on the wheel.

- `userInteracting : bool` (read-only)
  Reflects whether the surface is being dragged (from the interacting
  area). Used by the cursor expansion / animation gating.

## Signals

- `hueChanged()`
  Emitted when `hue` changes.

- `saturationChanged()`
  Emitted when `saturation` changes.

- `valueChanged()`
  Emitted when `value` changes.

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
    HSVWheel {
        colorAssistant: ca
        width: 200
        height: 200
        animationEnabled: false
    }
}
```

Drag on the wheel to pick `hue`/`saturation` (both written at once); the
cursor follows as a pure visualization of the value. Writing `value` dims
the wheel (darken alpha `1 - value`) without being touched by the surface
drag; the assistant stays the sole data source, so linked controls and
`HSVWheel` stay in step.
