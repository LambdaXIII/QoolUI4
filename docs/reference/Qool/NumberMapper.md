# NumberMapper

A piecewise-linear mapping utility: defines a curve through a list of
`NumberMapperStop` control points and maps any input `position` to an
interpolated output `value`. Declared in QML, queried at runtime — the
typical use is turning a continuous 0..1 input (e.g. a slider handle) into
a non-linear output curve (volume, temperature, exposure, easing-like
responses).

Each `NumberMapperStop` pairs a `position` (input axis) with a `value`
(output at that position). The stops form a piecewise-linear function:
between two adjacent stops the output is linearly interpolated
(`math::remap`); outside the stop range the output is clamped to the
nearest endpoint value (no extrapolation). With no stops the mapper returns
`0`; with a single stop it returns that stop's `value` constantly.

`stops` is the default property, so stops are declared as child objects.
Stops may be listed in any order — the mapper keeps an internally sorted
(lazy-cached) copy keyed by `position`. Adding/removing a stop or changing
a stop's `position`/`value` invalidates the cache and re-emits
`stopsChanged`.

`NumberMapper` also exposes ten preset sampling convenience properties
`position0..position9` (defaults `0.0..0.9`) paired with read-only
`value0..value9`, where `valueN == valueAt(positionN)`. These let QML
bind directly to ten fixed curve samples without calling `valueAt`
manually.

## Types

### `NumberMapperStop`

A single control point on the mapping curve.

- `position : real` (read/write, default `0`)
  Input-axis position of the stop.

- `value : real` (read/write, default `0`)
  Output value at this stop's `position`.

### `NumberMapper`

The mapper itself.

## Properties

- `stops : list<NumberMapperStop>`
  The ordered collection of control points (default property; read-only list
  assignment). Add/remove stops to shape the curve. Each added stop's
  `positionChanged` / `valueChanged` re-emits `stopsChanged`.

- `positionN : real` (read/write; N in `0..9`)
  Convenience input sample positions, defaulting to `N / 10`
  (`0.0`, `0.1`, …, `0.9`).

- `valueN : real` (read-only; N in `0..9`)
  Convenience output samples: `valueN == valueAt(positionN)`. Re-emitted
  whenever `positionN` or the curve (`stopsChanged`) changes.

## Signals

- `stopsChanged()`
  Emitted when a stop is added/removed or an existing stop's
  `position`/`value` changes.

## Methods

- `valueAt(position : real) : real`
  Maps a `position` to an output value. Returns `0` with no stops, the sole
  stop's `value` with one stop, clamps to the endpoint value outside the
  stop range, returns the exact stop value on a hit, and linearly
  interpolates between the bounding stops otherwise.

## Usage Example

```qml
import QtQuick
import Qool

// A slider 0..1 mapped to a curve: fast rise early, flat tail.
NumberMapper {
    id: mapper
    NumberMapperStop { position: 0.0; value: 0.0 }
    NumberMapperStop { position: 0.3; value: 0.8 }
    NumberMapperStop { position: 1.0; value: 1.0 }
}

Slider {
    // Drive a non-linear output from the handle position.
    value: mapper.valueAt(position) // or: mapper.value5
}
```
