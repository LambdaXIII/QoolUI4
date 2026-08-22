# ColorCursor

A private composite color-picking cursor shared by the HSV/HSL surfaces
(`_private` — consumed inside `Qool.Color`, not exposed to hosts). The
value position is the cursor's center point: the cursor is a pure
derivation of `position(...)` mapping output, **not** a draggable object.

`ColorCursor` composes three private pieces into one cursor contract:

- `CrystalCursor` (`Qool.Controls.Components`): the delayed-scale
  skeleton. Its inner `Crystal` carries its own precise diamond
  hit-testing — the four corners of the square footprint pass through,
  semantically equivalent to the old `Crystal4ContainmentMask` (the
  crystal is anchored to the root center, so presses outside the
  diamond fall through to the surface).
- `CenterPlacer` (`Qool`): `centerx`/`centery` ↔ `x`/`y` two-way
  placement on the root.
- `TimerLatch` (`Qool`): the value-change hold — a center change (=
  position change = surface value change) latches the expansion.

**Event-driven placement is mandatory.** `CenterPlacer` writes `x`/`y`
back explicitly on `onXChanged`, which **breaks any QML binding** that
assigns `centerx`/`centery` (an explicit write replaces the binding and
the cursor freezes). Consumers MUST assign `centerx`/`centery` from
signal handlers (event-driven `updateCursor()`), never from bindings.

## Properties

- `animationEnabled : bool`
  Animation switch — inherited up the parent chain (the host can turn it
  off uniformly on a parent), falling back to `Style.animationEnabled`.
  Passed through to the inner `CrystalCursor`.

- `currentColor : color` (default `"white"`)
  The cursor fill color, sourced by the consumer (e.g. the surface's
  solid color). Forwarded to the inner `CrystalCursor`'s `color`.

- `userInteracting : bool` (default `false`)
  Interaction state forwarded by the consumer (from its interacting
  area); one of the three expansion inputs.

- `centerx : real`
  The cursor center x — `property alias` to the internal
  `CenterPlacer` (reads `x + width/2`, writes proxy-set `x`). Write it
  from signal handlers only (see the event-driven placement warning).

- `centery : real`
  The cursor center y — mirror of `centerx`.

- `size : real` (default `20`)
  The component edge length (the root footprint is `size` × `size`).

- `expandDelta : real` (read-only)
  The expansion delta: `Qore.bound(4, size * 0.35, 15)`. Resting
  crystal edge = `size`, expanded = `size + expandDelta`.

## Behavior

- Visual semantics: the resting `Crystal` edge equals `size`; expanded
  it equals `size + expandDelta` (the internal `CrystalCursor` root is
  sized `size + expandDelta` with `delta = expandDelta`, centered on the
  root center — pixel-equivalent to the old `HSVWheelCursor` visuals).
- Three-way expansion: hover (square root domain, a superset of the old
  diamond domain — the same convention as the `Slider` handle),
  `userInteracting`, or the value-change latch (a center change
  re-arms a `TimerLatch` window of `Style.movementDuration * 2`). Any
  of the three holds `expanded = true`.
- Contract trim: no `latchTarget`, no `hoverEnabled`, no
  `defaultValue`/`reset` (double-click undefined), no `centerPoint`.

## Signals

- `centerxChanged()`
  Emitted when `centerx` changes (forwarded from the internal
  `CenterPlacer`).

- `centeryChanged()`
  Emitted when `centery` changes.

## Methods

This type defines no additional methods.

## Usage Example

The `HSVWheel` internal wiring pattern — event-driven placement from
surface signals, never bindings:

```qml
// Inside an InteractingArea / surface consumer
ColorCursor {
    objectName: "wheelCursor"
    animationEnabled: root.animationEnabled
    currentColor: root.colorAssistant.solidColor
    userInteracting: root.userInteracting
}

function updateCursor() {
    const p = surface.position(root.colorAssistant.hsvHueF,
                               root.colorAssistant.hsvSaturationF)
    cursor.centerx = p.x
    cursor.centery = p.y
}
```

The consumer places the cursor from its own channel-change signals
(`onHsvHueFChanged` / `onHsvSaturationFChanged` → `updateCursor()`) and
once on `Component.onCompleted` for the initial position. Writing
`centerx`/`centery` in a QML binding instead freezes the cursor —
`CenterPlacer`'s explicit write-back replaces the binding.
