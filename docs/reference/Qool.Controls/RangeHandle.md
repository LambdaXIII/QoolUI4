# RangeHandle

The range interaction component of the `RangeSlider` family: an `Item`
that owns everything about the interval interaction except its appearance —
the three-zone drag zones, the endpoint hit-zone extension, and the cursor
shapes. It is a public standalone component (usable outside `RangeSlider`
for self-built slider scenarios) and the behavior-plug seam of
`RangeSlider` (subclass it and replace the `rangeHandle` property).

`RangeHandle` is deliberately value-model-free and position-free: it does
not receive endpoint positions and does not emit result positions. The
three zones emit *intent* signals (`wannaMoveFirstX`/`wannaMoveSecondX`/
`wannaMoveRangeX`) whose payload is a **pixel delta** (the drag
displacement since the previous event, in the scene's coordinates). The
value↔position mapping, the delta→value conversion, and the endpoint
clamping all live in the host (in `RangeSlider` they live in the
`availableWidth` travel formula and the signal `Connections`).

The `surface` (default: a plain placeholder `Rectangle`) is a pure
appearance plug: `RangeHandle` only sets its `parent` — the surface is
responsible for its own layout (the default instance `anchors.fill`s this
component). Replacing it swaps the appearance without touching the
interaction.

## Properties

- `surface : Item`
  The appearance plug. Default: a `Rectangle` with `anchors.fill: parent`
  (border `Style.buttonText`, fill `Style.accent`). Layout is the
  surface's own responsibility — `RangeHandle` does not impose
  x/y/width/height/color. In `RangeSlider`, the default surface is
  overridden by an `Item` that fills the interval box and hosts the
  crystal foreground.
- `firstMouseZoneExtension : real` (default `2`)
  The left zone's hit-zone extension in pixels: the zone starts at
  `-extension` (overflowing the component's left edge).
- `secondMouseZoneExtension : real` (default `firstMouseZoneExtension`)
  The right zone's hit-zone extension: the zone's right edge is
  `width + extension` (overflowing the right edge).
- `down : bool` (read-only)
  Whether any of the three zones is pressed.
- `hovered : bool` (read-only)
  Whether any of the three zones is hovered. (Both `down` and `hovered`
  are aggregates a host surface can use for expansion feedback.)
- `firstCursorShape : enumeration` / `secondCursorShape : enumeration`
  Aliases for the left/right zone cursor shapes. Default: `Qt.SplitHCursor`
  (the middle zone is always `Qt.SizeHorCursor`).

The default implicit size is 0 × 0 (the component is normally given
geometry by its host — in `RangeSlider` via the interval-box bindings).

## Signals

- `wannaMoveFirstX(real x)`
  Emitted while dragging the left zone — the drag displacement in pixels
  (delta since the previous event). The host converts it to a value delta
  and writes `first`.
- `wannaMoveSecondX(real x)`
  Emitted while dragging the right zone — the drag displacement in pixels.
- `wannaMoveRangeX(real x)`
  Emitted while dragging the middle zone — the drag displacement in pixels
  (the host shifts both endpoints together and clamps the shift as a whole
  at the range boundary).

The payload `x` is a **delta**, not a position: the signals are intent
requests ("I want to move by this much"), and the host decides how to
apply them. Clamping is not part of the drag path here — it moved to the
host's value domain.

## Methods

This type defines no methods.

## Zone geometry

The three zones partition the component physically (they do not overlap;
both endpoint zones overflow by their extension):

- left zone: `x = -extension`, `width = min(width/2, height/2) + extension`
- middle zone: `x = height/2`, `width = width - height` (the travel — the
  range where the endpoint centers move)
- right zone: `x = width - min(width/2, height/2)`, `width = min(width/2,
  height/2) + extension`

With `width >= height` the zones are seamless: left `[-ext, h/2]`, middle
`[h/2, w - h/2]`, right `[w - h/2, w + ext]`. The partition derives from
the component's own geometry (`height` as the handle basis) and is
independent of the surface's actual size — stable across expanded/resting
states.

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

// Standalone: connect the intent signals and convert to values yourself.
RangeHandle {
    width: 300
    height: 25
    onWannaMoveFirstX: dx => console.log("first wants", dx, "px")
    onWannaMoveSecondX: dx => console.log("second wants", dx, "px")
    onWannaMoveRangeX: dx => console.log("range wants", dx, "px")
}

// Inside RangeSlider — the interval-box geometry and the signal
// conversion are applied automatically; replace the surface for a custom
// look (the surface lays itself out, e.g. anchors.fill: parent).
RangeSlider {
    rangeHandle: RangeHandle {
        surface: Rectangle {
            anchors.fill: parent
            radius: 3
            color: Style.active.accent
        }
    }
}

// Behavior plug: subclass and override (here: log the drag payloads
// without changing the default interaction).
component LoggingHandle: RangeHandle {
    onWannaMoveFirstX: dx => console.log("firstMoved delta", dx)
    onWannaMoveSecondX: dx => console.log("secondMoved delta", dx)
    onWannaMoveRangeX: dx => console.log("rangeMoved delta", dx)
}

RangeSlider {
    rangeHandle: LoggingHandle {}
}
```

## Layout contract

- The surface's `parent` is bound to this component (a `Binding` retargeted
  automatically when the surface is replaced).
- Everything else — the surface's own geometry and any expansion feedback —
  is the surface's responsibility. The default placeholder fills the
  component; `RangeSlider`'s default surface fills the interval box and
  hosts the crystal foreground with its own overflow geometry.
