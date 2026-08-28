# CrystalCursor

A delayed-scale behavior component — a `Crystal` diamond with an
expand/contract scale driven by a single boolean input, wrapped in a
stable Item root. The base component behind the color cursor family
(slider handles, surface cursors).

`CrystalCursor` is the shared skeleton of the cursor/handle family:
a `Crystal` diamond (which carries its own precise diamond hit-testing —
the four corners of the square footprint pass through, no mask component
needed), delayed expand/contract scaling, and outsourced color. The
component owns **only** the scaling capability; positioning and color
sourcing stay with the consumer.

## Behavior

- `expanded` is the only behavioral input: `true` expands to the full
  root size **immediately** (expansion is never delayed — responsive
  feedback), `false` contracts to the resting size only after the
  `delay` window. The fall direction is gated through a `TimerLatch`:
  an `expanded` change re-arms the latch, so the expanded state holds
  through `delay` and only then settles to `false` — a debounce that
  prevents flicker on quick state changes. The component listens to
  **no value signals**; consumers fold their own hover / pressed /
  value-change conditions into a single boolean and feed `expanded`.
- Scale: the inner `Crystal` animates from `fullSize − delta` (resting)
  to `fullSize` (expanded) via `ItemAnimatedResizer`. The scale is
  **always animated** — the resizer is hard-wired `animationEnabled:
  true`; `Style.animationEnabled` gates only the color transitions
  (internal `BasicColorBehavior on color/borderColor`).
- The root keeps a constant footprint (the consumer sets its size):
  scaling applies only to the inner `Crystal`, so the root stays a
  stable positioning anchor. With a rectangular root the diamond
  inscribes the shorter edge and centers itself — `fullSize` is that
  inscribed edge.
- The diamond hit test (`Crystal`'s own containment) follows the inner
  diamond geometry, so corners of a square footprint pass through —
  no separate mask component is needed.

## Properties

- `expanded : bool` (default `true`)
  The only behavioral input. `true` expands immediately (self-consistent
  default — standalone use renders expanded), `false` contracts to the
  resting size after the `delay` window (debounced fall — quick state
  changes do not flicker).

- `delta : real`
  The scale delta: resting size = `fullSize − delta`, expanded =
  `fullSize`. Default derives from the family convention
  (`Qore.bound(3, fullSize * 0.25, 25)`).

- `delay : int`
  The debounce window for the contract direction only (a `TimerLatch`
  interval). Expansion is immediate — `delay` gates only how long the
  expanded state holds after `expanded` turns `false`, absorbing quick
  state changes (no flicker). Default `Style.transitionDuration` (200 in
  the system theme). Long value-change hold
  windows are the consumer's latch (folded into `expanded`); this
  component does not hold long by default.
- `color : color`
  The fill color, outsourced to the consumer. Default `Style.accent`
  (self-consistent for standalone use).

- `borderColor : color`
  The inner stroke-ring color. Default is an automatic contrast against
  `color` via `ThemeHQ.recommendForeground`.

- `fullSize : real` (read-only)
  The diamond's full edge = `min(root.width, root.height)` — the
  inscribed size for a rectangular root.

- `size : real` (read-only)
  The inner `Crystal`'s current edge length (dynamic — resting or
  expanded, mid-animation included).

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls.Components

// Standalone: a diamond that expands while expanded is true.
CrystalCursor {
    width: 40
    height: 40
    expanded: myHovered || myPressed
}

// Consumer folds its own conditions into the single bool input.
CrystalCursor {
    width: 40
    height: 40
    delta: 10
    expanded: hoverer.hovered || root.pressed || latch.active
    color: solidColor
}
```
