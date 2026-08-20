# ItemAnimatedResizer

A resized-driven two-way size switcher: `resized` being `true` advances the
size to the `to` target (expand), `false` retreats to the `from` target
(contract). Non-visual (`SmartObject`); hosts bind or assign `resized` and
the component animates (or jumps) between the two target sizes.

The typical use is expand/contract feedback on a foreground or decoration:
`RangeSlider` expands its interval foreground on hover / value-change latch,
and `Slider` switches its handle between the rest and expanded sizes — both
via this type. Because it is non-visual, the size (`width`/`height`) is
usually bound to a visual's geometry.

`resized` is a direction switch, not a one-shot command: setting it `true`
moves the size to the `to` target, `false` back to the `from` target.
Repeated toggles are safe; the last direction wins. While a direction is
reached (after the animation finishes or after a jump), the size is pinned
to that target by an internal binding, so later changes to
`fromWidth`/`toWidth` etc. follow live — the targets are bindings, not
snapshots.

`enabled` gates the response to `resized` changes: when `false`, `resized`
changes are ignored and the size freezes at its current value. Hosts
usually tie it to a control's `enabled` so the feedback is fully static
while the control is disabled (see `RangeSlider`, which wires
`enabled: root.enabled`).

`animationEnabled` gates the animation: when on (and the direction
template's `duration` is positive) the transition animates; when off, it
jumps. It inherits up the parent chain (the host can turn it off uniformly
on a parent), falling back to `Style.animationEnabled`.

`forewardAnimation` / `backwardAnimation` expose the `NumberAnimation`
templates for the two directions; hosts can customize `easing` and
`duration` independently.

## Properties

- `enabled : bool` (default `true`)
  Gates the response to `resized` changes. When `false`, `resized` changes
  are ignored and the size freezes at its current value; restoring `true`
  resumes response (a `resized` change after re-enabling is required to
  act).

- `animationEnabled : bool`
  Animation gate — inherited up the parent chain, falling back to
  `Style.animationEnabled`. When on and the direction template's `duration`
  is positive, direction switches animate; otherwise they jump.

- `resized : bool` (default `false`)
  Direction switch: `true` advances the size to the `to` target (expand),
  `false` retreats to the `from` target (contract).

- `fromWidth : real` (default `100`)
  The retreat target width (used while `resized` is `false`).

- `fromHeight : real` (default `100`)
  The retreat target height (used while `resized` is `false`).

- `toWidth : real` (default `120`)
  The advance target width (used while `resized` is `true`).

- `toHeight : real` (default `120`)
  The advance target height (used while `resized` is `true`).

- `width : real` (read-only)
  The current width — the `from`/`to` target when a direction is reached,
  an intermediate value while animating.

- `height : real` (read-only)
  The current height — the `from`/`to` target when a direction is reached,
  an intermediate value while animating.

- `running : bool` (read-only)
  Whether either direction animation is currently running.

- `forewardAnimation : NumberAnimation`
  The advance animation template (easing/duration). Used when `resized`
  becomes `true`.

- `backwardAnimation : NumberAnimation`
  The retreat animation template (easing/duration). Used when `resized`
  becomes `false`.

## Signals

This type defines no additional signals.

## Methods

This type defines no additional methods.

## Usage Example

```qml
import QtQuick
import Qool

// Foreground size switcher: expands on hover / value-change latch,
// contracts otherwise (the RangeSlider pattern).
ItemAnimatedResizer {
    id: resizer
    enabled: root.enabled
    animationEnabled: root.animationEnabled

    fromWidth: restWidth
    fromHeight: restHeight
    toWidth: expandedWidth
    toHeight: expandedHeight

    resized: hovered || latch.active
}

// Bind the switched size to a visual.
Rectangle {
    width: resizer.width
    height: resizer.height
}

// Custom per-direction rhythm.
ItemAnimatedResizer {
    fromWidth: 10
    fromHeight: 10
    toWidth: 100
    toHeight: 100
    resized: expanded

    forewardAnimation.duration: 120   // expand fast
    backwardAnimation.duration: 300   // contract slow
}
```
