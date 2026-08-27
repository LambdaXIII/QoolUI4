# ColorMapper

A gradient mapping utility: defines a color ramp through a list of
`ColorMapperStop` control points and maps any input `position` to an
interpolated output `color`. Declared in QML and queried at runtime — the
typical use is turning a continuous `0..1` input (e.g. a slider handle) into
a color gradient (a temperature scale, an exposure ramp, a status color
bar).

Each `ColorMapperStop` pairs a `position` (input axis) with a `color`
(output at that position). Between two adjacent stops the color is
interpolated channel-wise, linearly, in the color space selected by `mode`.
With no stops the mapper returns `Qt.white`; with a single stop it returns
that stop's `color` constantly.

`stops` is the default property, so stops are declared as child objects.
Stops may be listed in any order — the mapper keeps an internally sorted
(lazy-cached) copy keyed by `position`. Adding/removing a stop or changing
a stop's `position`/`color` invalidates the cache and recomputes the preset
colors.

`ColorMapper` also exposes ten preset sampling convenience properties
`position0..position9` (defaults `0.0..0.9`) paired with read-only
`color0..color9`, where `colorN == colorAt(positionN)`. These let QML bind
directly to ten fixed gradient samples without calling `colorAt` manually.

## Types

### `ColorMapperStop`

A single control point on the gradient.

- `position : real` (read/write, default `0`)
  Input-axis position of the stop.

- `color : color` (read/write, no default — initially invalid/transparent)
  Color at this stop's `position`. The color is stored as given; conversion
  to `mode`'s color space happens at interpolation time.

### `ColorMapper`

The mapper itself.

## Properties

- `stops : list<ColorMapperStop>`
  The collection of control points (default property; read-only list
  assignment — assigning a non-default-property list replaces the current
  stops). Add/remove stops to shape the gradient. Each added stop's
  `positionChanged` / `colorChanged`, and each add/remove, recomputes the
  gradient and re-emits `colorNChanged` for all samples.

- `mode : enumeration`
  The color space used to interpolate between stops, default `RGB`. One of:

  - `ColorMapper.RGB` — interpolate the red, green and blue channels.
  - `ColorMapper.HSV` — interpolate hue, saturation and value.
  - `ColorMapper.HSL` — interpolate hue, saturation and lightness.
  - `ColorMapper.CMYK` — interpolate cyan, magenta, yellow and black.

  Final (`FINAL`): a subclass cannot override it. Changing `mode` recomputes
  all preset colors and re-emits `colorNChanged`. Hue is interpolated
  linearly on its numeric value in the chosen space — there is no
  shortest-arc wrapping.

- `positionN : real` (read/write; N in `0..9`)
  Convenience input sample positions, defaulting to `N / 10`
  (`0.0`, `0.1`, …, `0.9`).

- `colorN : color` (read-only; N in `0..9`)
  Convenience output samples: `colorN == colorAt(positionN)`. Re-emitted
  whenever `positionN` changes or the gradient updates (a stop added/removed,
  a stop's `position`/`color` changed, or `mode` changed).

## Signals

- `colorNChanged()` (N in `0..9`)
  Emitted when `colorN`'s value changes — i.e. when its `positionN` changes,
  or when the gradient (stop add/remove, a stop's `position`/`color` change,
  or a `mode` change) makes `colorN` take a new value.

## Methods

- `colorAt(position : real) : color`
  Maps a `position` to a color. Behavior:

  - With no stops, returns `Qt.white` regardless of `position`.
  - With exactly one stop, returns that stop's `color` regardless of
    `position`.
  - With two or more stops, the stops are sorted by `position` (a stable
    sort, so stops sharing a position keep their declaration order):
    - If `position` equals a stop's `position`, that stop's exact `color`
      is returned (an exact hit short-circuits, no interpolation).
    - For a `position` strictly between two adjacent stops, the color is
      linearly interpolated channel-wise in `mode`'s color space: the alpha
      channel is remapped from the two stops' alpha values, and each color
      channel of the mode is remapped and clamped to `[0, 1]`.

  **Precondition / boundary:** a `position` before the smallest stop's
  position returns the first stop's `color`; a `position` after the largest
  stop's position returns the last stop's `color` (clamped, no
  extrapolation).

## Usage Example

```qml
import QtQuick
import Qool

// A temperature ramp: blue (cold) → green → red (hot).
ColorMapper {
    id: tempMap
    mode: ColorMapper.RGB
    ColorMapperStop { position: 0.0; color: "steelblue" }
    ColorMapperStop { position: 0.5; color: "limegreen" }
    ColorMapperStop { position: 1.0; color: "firebrick" }
}

Slider {
    // Drive the ramp from the handle position, or use tempMap.color5.
    color: tempMap.colorAt(position)
}
```
