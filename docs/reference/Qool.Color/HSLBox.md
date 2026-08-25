# HSLBox

A regenerable, public HSL two-dimensional color-picking surface: a
rectangular box that responds to the mouse to pick `saturation`/`lightness`
while `hue` drives the plane's hue, shaped as a single reusable
`Qool.Color` component (v4, new design). `HSLBox` uses a **single-chain
architecture** aligned with the public `HSVWheel`.

- **Single chain, no loop**: mouse events flow one way —
  `mouse → setValues() → sat/ltn data → position(sat,ltn) → cursor`. The
  cursor is a *visualization of the value* (a pure derivation of
  `position`), not a separately draggable object, and the box reads the same
  data source independently. There is **no** "cursor ↔ value" two-way
  binding.
- **Atomic writes**: one mouse event writes `hue`/`saturation`/`lightness`
  together through the `hslF` list setter (a single recompute round, one
  broadcast — no intermediate timing states). Interaction does **not**
  change `hue` — it takes the assistant's current anchored hue (always
  valid, ADR-0020), so a gray-axis pick remembers the hue while the plane
  keeps picking against the current hue.
- **Clamping for value validity** (not coordinate clamping): interactive
  writes keep `HSLSurface`'s existing mapping (`Tools.limitNumber`
  rectangle clipping → `saturationAt = x/w`, `lightnessAt = 1 - y/h`);
  the interface-level `hue`/`saturation`/`lightness` property writes
  normalize: `hue` wraps modulo into `[0,1)` (`-0.5 → 0.5`, `1.5 → 0.5` —
  always valid), `saturation`/`lightness` clamp to `[0,1]`. `position`
  stays a pure function.
- **Geometry relocation**: resizing the surface repositions the cursor via
  `onWidthChanged`/`onHeightChanged` handlers (the cursor is
  event-positioned, so a size change alone would leave it stale).
- **No `defaultValue`/`reset`, double-click undefined** — the interaction
  contract is trimmed to match `ColorChannelSlider`/`ColorChannelControl`
  (and `HSVWheel`). Unlike the wheel there is no ring clamp — the whole
  rectangle is a hit target, clipped linearly.
- The `_private` surface (`HSLSurface`) stays private; the cursor is an
  **inline `CrystalCursor` + `CenterPlacer` wiring** inside the interacting
  area (same inline wiring as `HSVWheel` — each surface hosts its own copy;
  there is no shared `_private` `ColorCursor` composite, ADR-0017). The
  public surface is the composition. Cursor positioning is **event-driven**
  (`updateCursor()` on assistant channel changes) — binding `centerx`/
  `centery` is forbidden (the placer's explicit back-write breaks bindings).

## Properties

- `animationEnabled : bool`
  Animation switch (inherited from the parent chain — defaults to
  `Style.animationEnabled`). Declared first (repository convention).

- `colorAssistant : ColorAssistant` (default: `ColorAssistant {}`)
  The color object that is the single data source. Interaction writes
  `saturation`/`lightness`; `hue` drives the plane's hue but is not written
  by the surface. Default standalone instance makes `HSLBox` usable on its
  own.

- `hue : real`
  The hue channel (0..1). Two-way: writing it updates the assistant's
  `hslHueF`; a change from the assistant reads back. Out-of-range writes
  are normalized modulo into `[0,1)` (`-0.5 → 0.5`, `1.5 → 0.5`) — the
  hue reading is always valid (anchors, ADR-0020); on the gray axis
  (saturation 0) the written hue is remembered by the assistant anchor
  even though the color stays achromatic. Not written by surface
  interaction (external / linked).

- `saturation : real`
  The saturation channel (0..1). Two-way; interface writes clamp to
  `[0,1]`.

- `lightness : real`
  The lightness channel (0..1). Two-way; interface writes clamp to
  `[0,1]`. Defaults to `1` (white; the seeding pass overwrites it from the
  assistant on creation).

- `userInteracting : bool` (read-only)
  Reflects whether the surface is being dragged (from the interacting
  area). Used by the cursor expansion / animation gating.

## Signals

- `hueChanged()`
  Emitted when `hue` changes.

- `saturationChanged()`
  Emitted when `saturation` changes.

- `lightnessChanged()`
  Emitted when `lightness` changes.

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
    HSLBox {
        colorAssistant: ca
        width: 200
        height: 200
        animationEnabled: false
    }
}
```

Drag on the box to pick `saturation`/`lightness` (both written at once); the
cursor follows as a pure visualization of the value. Writing `hue` (or
linking it from a channel row) rotates the plane's hue without being touched
by the surface drag; the assistant stays the sole data source, so linked
controls and `HSLBox` stay in step. Double-clicking does nothing (the reset
contract is trimmed, matching `HSVWheel`).
