# ColorCursor

A private composite color-picking cursor (`_private` — consumed inside
`Qool.Color`, not exposed to hosts). The value position is the cursor's
center point: the cursor is a pure derivation of `position(...)` mapping
output, **not** a draggable object.

`ColorCursor` composes two private pieces into one cursor contract:

- `CrystalCursor` (`Qool.Controls.Components`): the delayed-scale
  skeleton. Its inner `Crystal` carries its own precise diamond
  hit-testing — the four corners of the square footprint pass through,
  semantically equivalent to the old `Crystal4ContainmentMask` (the
  crystal is anchored to the root center, so presses outside the
  diamond fall through to the surface).
- `CenterPlacer` (`Qool`): `centerx`/`centery` ↔ `x`/`y` two-way
  placement on the root.

**Event-driven placement is mandatory.** `CenterPlacer` writes `x`/`y`
back explicitly on `onXChanged`, which **breaks any QML binding** that
assigns `centerx`/`centery` (an explicit write replaces the binding and
the cursor freezes). Consumers MUST assign `centerx`/`centery` from
signal handlers (event-driven `updateCursor()`), never from bindings.

> Current status: **orphan component** — no consumer instantiates
> `ColorCursor` today. `HSVWheel` and `HSLBox` each wire an inline
> `CrystalCursor` + `CenterPlacer` + `TimerLatch` + `updateCursor()` inside
> their own interacting area (ADR-0017) instead of using this composite.
> The file-header comment mentions a `TimerLatch` value-change latch, but
> the implementation contains no `TimerLatch` instance — only
> `CenterPlacer` + `CrystalCursor`.

## Properties

- `animationEnabled : bool`
  Animation switch — inherited up the parent chain (the host can turn it
  off uniformly on a parent), falling back to `Style.animationEnabled`.
  Passed through to the inner `CrystalCursor`.

- `currentColor : color` (default `"white"`)
  The cursor fill color, sourced by the consumer (e.g. the surface's
  solid color). Forwarded to the inner `CrystalCursor`'s `color`.

- `expanded : bool` (default `false`)
  The expansion input, folded by the consumer from its interaction state
  (hover / interacting / value-change latch — the consumer reduces its own
  conditions to this single boolean, per ADR-0016). Forwarded to the inner
  `CrystalCursor`'s `expanded`.

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
  it equals `size + expandDelta` (the inner `CrystalCursor` root is
  sized `size + expandDelta` with `delta = expandDelta`, centered on the
  root center — pixel-equivalent to the old `HSVWheelCursor` visuals).
- Expansion: the consumer folds hover / interacting / value-change latch
  into the single `expanded` boolean (any of the three holds
  `expanded = true`).
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

The `HSVWheel`-style wiring pattern — event-driven placement from
surface signals, never bindings:

```qml
// Inside an InteractingArea / surface consumer
ColorCursor {
    objectName: "wheelCursor"
    animationEnabled: root.animationEnabled
    currentColor: root.colorAssistant.solidColor
    expanded: area.userInteracting || latch.active || hoverer.hovered
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
