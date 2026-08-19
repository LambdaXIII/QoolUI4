# RangeSlider

An interval slider built in three layers: a static hexagonal track, a
`RangeHandle` (the interval logic container), and a pluggable `surface`
(by default a single crystal foreground spanning the whole interval).
The selected interval is displayed as one unified shape — left point +
straight middle + right point — instead of two separate handles.

`RangeSlider` keeps the full `T.RangeSlider` API (`first`/`second` values,
`from`, `to`, `setValues()`, keyboard stepping — template behavior). The
three-layer structure decouples behavior from appearance:

- **Layer 1 — value model + static background**: the `T.RangeSlider`
  template and a static `Crystal` hexagonal track (`Style.text`, single
  color, no gradient). The track does not participate in interaction
  feedback (the visual focus is on the foreground).
- **Layer 2 — `RangeHandle`**: a public standalone component holding all of
  the interval logic — spatial positions, three-zone drag interaction, and
  `surface` layout control. Replacing the `rangeHandle` property with a
  subclass instance is **behavior plugging**.
- **Layer 3 — `surface`**: an `Item` property (default: `Crystal`) whose
  layout (x/y/width/height/color) is imposed by the `RangeHandle` — the
  surface does not respond to value data itself. Replacing it with any
  `Item` is **appearance plugging**; the two plug points are independent.

Interaction: three-zone partition drag — the left zone drags `first`, the
right zone drags `second`, the middle zone drags the whole interval
(synchronized shift, interval width unchanged, boundary-clamped as a whole).
Clicks do nothing (the template's "click jumps" is not kept); keyboard
behavior is the template's.

## Properties

- `color : color` (default `Style.accent`)
  The foreground fill color — companion-bound to `rangeHandle.color`.
  Changing it changes the whole interval visual.

- `justMoved : bool`
  "A value was just written" declarative latch window — 500 ms, sliding
  (continuous changes keep it held). `true` while any value change is within
  the window. Companion-bound to `rangeHandle.externalExpanded` — the
  foreground expands while the window is held.

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain (the host can turn it off
  uniformly on a parent), falling back to `Style.animationEnabled`.

- `preferredHeight : real` (read-only)
  Resting height of the track and the foreground surface (contracted state)
  — `root.height - Qore.bound(3, root.height * 0.25, 25)`. When expanded the
  surface fills the control's full height. Usable by the host in external
  layout calculations.

- `rangeHandle : RangeHandle`
  The interval logic container (default: an internal instance). Replacing it
  with a subclass instance overrides behavior — **behavior plugging**. The
  companion bindings (`firstPosition`, `secondPosition`, `cutSize`,
  `preferredHeight`, `externalExpanded`, `animationEnabled`, `color`) and
  the signal-to-value conversion (`firstMoved`/`secondMoved`/`rangeMoved`)
  are applied dynamically — a replaced instance is controlled the same way.

- `firstPosition : real` / `secondPosition : real` (read-only)
  The endpoint positions in the control's coordinates (the value→position
  mapping, `RangeSlider`'s responsibility — the value model stays in the
  template): `leftPadding + visualPosition × (availableWidth − height) +
  height/2`.

- `surface : Item`
  The appearance plug (accessed via `rangeHandle.surface`). Default: a
  `Crystal` foreground — the straight middle segment exactly spans the
  interval, the 45° points overflow by `cutSize` on both ends; when the
  endpoints coincide the shape degrades to a crystal (diamond). Replacing
  it with any simple `Item` (e.g. a `Rectangle`) auto-fills the correct
  interval × height — no value→position mapping needed on the host side.

Inherited from `T.RangeSlider`: `first`, `second` (each a `RangeSliderHandle`
with `value`/`position`/`visualPosition`/`pressed`), `from`, `to`,
`stepSize`, `snapMode`, `live`, `active`, and all other
`RangeSlider`/`Control` members. See the Qt documentation for the inherited
members. The default implicit size is 80 × 25.

## Signals

This type defines no additional signals (inherits all signals from
`T.RangeSlider`, notably `first.moved()` and `second.moved()`).

## Methods

This type defines no additional methods (inherits all methods from
`T.RangeSlider`, notably `setValues()`).

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Controls

RangeSlider {
    width: 300
    from: 0
    to: 100
    // Official contract: set both values at once via setValues()
    // (first.value/second.value have a circular dependency; assigning
    // them separately before completion may clamp each other).
    Component.onCompleted: setValues(25, 75)
}

// Custom interval color.
RangeSlider {
    width: 300
    color: Style.active.accent
}

// Appearance plug: replace the surface with any Item — the RangeHandle
// imposes x/y/width/height/color, so a plain Rectangle fills the interval
// automatically (no value→position mapping needed).
RangeSlider {
    width: 300
    rangeHandle: RangeHandle {
        surface: Rectangle {
            radius: 3
            color: Style.active.accent
        }
    }
}

// Behavior plug: subclass RangeHandle, then replace the property.
// The companion bindings and the signal conversion apply to the
// replacement instance as well.
RangeSlider {
    width: 300
    rangeHandle: LoggingHandle {}
}
```

## Interaction feedback

- Three-zone drag: the left zone (within `height/2` of `first`) drags
  `first`, the right zone (within `height/2` of `second`) drags `second`,
  the middle zone drags the whole interval — both endpoints shift together,
  the interval width stays constant, and the shift stops at the range
  boundary as a whole. The zone boundaries derive from the value geometry
  (`W = height/2`) and do not depend on the surface's actual size.
- Clicks do nothing — the interaction is drag-only (the template's
  "click jumps to the nearest handle" is not kept); keyboard stepping
  remains the template's behavior.
- Hover / press / just-moved (the 500 ms window after a value change): the
  foreground expands to the control's full height (resting =
  `preferredHeight`), keeping vertical centering and its width; animated
  under the `animationEnabled` gate. When expanded, the 45° points push out
  of the track's top/bottom bounds (the same semantics as the `Slider`
  handle expansion). Programmatic value writes expand the foreground via
  `justMoved` even when the control is disabled (data feedback does not
  follow interaction disablement).
- Inverted range (`from > to`): positions reverse; the interval stays
  positive (the template guarantees `first.position <= second.position`).
- Narrow intervals: the `Crystal` cut follows the shape's own geometry
  (`min(width, height)/2`), so a narrow interval auto-degrades to a
  capsule/diamond and a zero-width interval (coincident endpoints) to a
  crystal (diamond) — no special casing.
