# RangeHandle

The interval logic container of the `RangeSlider` family: an `Item` that
owns everything about the interval except its appearance — spatial
positions, the three-zone drag interaction, and the `surface` layout. It is
a public standalone component (usable outside `RangeSlider` for
self-built slider scenarios) and the behavior-plug seam of `RangeSlider`
(subclass it and replace the `rangeHandle` property).

`RangeHandle` is deliberately value-model-free: it receives endpoint
positions (`firstPosition`/`secondPosition`) in its parent's coordinates
and emits new positions / pixel deltas (`firstMoved`/`secondMoved`/
`rangeMoved`). The value↔position mapping stays in the host (in
`RangeSlider` it lives in the template's `leftPadding`/`availableWidth`
travel formula) — the handle never copies template travel semantics.

The `surface` (default: a `Crystal` foreground) is a pure appearance plug:
the handle imposes its x/y/width/height/color via bindings, so replacing it
with any simple `Item` auto-fills the correct interval × height — the
surface never responds to value data itself.

## Properties

- `firstPosition : real` (default `0`)
  The `first` endpoint position in the parent's coordinates — the surface's
  left reference and the left-zone drag target.
- `secondPosition : real` (default `0`)
  The `second` endpoint position in the parent's coordinates.
- `cutSize : real` (default `preferredHeight / 2`)
  The surface's left/right overflow amount. The default matches the default
  `Crystal` surface's point overflow (`preferredHeight / 2`); a host that
  replaces the surface adjusts it as needed (e.g. `cutSize: 0` for an exact
  fill). The handle does not switch layout modes automatically.
- `preferredHeight : real` (default `root.height - Qore.bound(3,
  root.height * 0.25, 25)`)
  The surface's resting height (the `Slider` family contraction formula).
- `externalExpanded : bool` (default `false`)
  An external expansion source (companion-bound to the host's `justMoved`).
  Composes with the internal `pressed`/`hovered` into `expanded`.
- `color : color` (default `Style.accent`)
  The surface fill color (companion-bound to the host's `color`); applied to
  the surface only when it has a `color` property.
- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`. Gates the
  default surface's expansion animation.
- `surface : Item`
  The appearance plug. Default: a `Crystal` foreground whose straight middle
  segment exactly spans the interval and whose 45° points overflow by
  `cutSize` on both ends; coincident endpoints degrade it to a crystal
  (diamond) automatically. Replacing it with any `Item` swaps the appearance
  without touching the interaction.
- `expanded : bool` (read-only)
  `externalExpanded || pressed || hovered` — the surface height switch.
- `surfaceHeight : real` (read-only)
  The surface height: the control's full height when expanded, otherwise
  `preferredHeight`.
- `midPosition : real` (read-only)
  The interval center `(firstPosition + secondPosition) / 2` — one of the
  three zone mid-values (endpoint positions + interval center) a custom
  surface or host can use to sense the partition.
- `zoneWidth : real` (read-only)
  The zone boundary width `height / 2` — the three-zone partition derives
  from the value geometry and does not depend on the surface's actual size
  (stable across expanded/resting states).

The default implicit size is 80 × 25.

## Signals

- `firstMoved(real newPosition)`
  Emitted while dragging the left zone — the new `first` endpoint position
  (parent coordinates; the payload is the position, the host converts it to
  a value). The endpoint clamping (travel range, not crossing `second`) is
  part of the drag path.
- `secondMoved(real newPosition)`
  Emitted while dragging the right zone — the new `second` endpoint
  position (parent coordinates).
- `rangeMoved(real delta)`
  Emitted while dragging the middle zone — the pixel displacement since the
  previous event (the host converts it to a value delta, shifts both
  endpoints together, and clamps the shift as a whole at the range
  boundary).

## Methods

This type defines no additional methods. (`zoneAt(x)`, `clampFirst(pos)`
and `clampSecond(pos)` are internal helpers of the drag path; a subclass
may call them from overridden behavior.)

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

// Standalone: bind positions and convert the signals yourself.
RangeHandle {
    width: 300
    height: 25
    firstPosition: 80
    secondPosition: 220
    onFirstMoved: pos => console.log("first →", pos)
}

// Inside RangeSlider — the companion bindings and the signal conversion
// are applied automatically; replace the surface for a custom look.
RangeSlider {
    rangeHandle: RangeHandle {
        surface: Rectangle {
            radius: 3
            color: Style.active.accent
        }
    }
}

// Behavior plug: subclass and override (here: log the drag payloads
// without changing the default interaction).
component LoggingHandle: RangeHandle {
    onFirstMoved: pos => console.log("firstMoved", pos)
    onSecondMoved: pos => console.log("secondMoved", pos)
    onRangeMoved: delta => console.log("rangeMoved", delta)
}

RangeSlider {
    rangeHandle: LoggingHandle {}
}
```

## Surface layout contract

The handle imposes on the surface (via bindings, re-targeted automatically
when the surface is replaced):

- `x` = `firstPosition − cutSize` (the left point overflows the interval)
- `width` = `secondPosition − firstPosition + 2 × cutSize` (points overflow
  on both ends)
- `y` = `(height − surfaceHeight) / 2` (vertical centering; the surface
  height switch is the only thing that changes on expansion — the width
  stays constant)
- `height` = `surfaceHeight` (`preferredHeight` resting / control height
  expanded)
- `color` = `color` (only when the surface has a `color` property)

The default `Crystal` surface's own cut follows its geometry
(`min(width, height)/2`), so at rest the straight middle segment exactly
spans the interval, and narrow/degenerate intervals (down to coincident
endpoints) auto-reasonable without special casing.
