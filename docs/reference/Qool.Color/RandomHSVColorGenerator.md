# RandomHSVColorGenerator

A constrained random HSV color generator: per-channel random ranges plus
locking and anti-repeat.

All inputs are 0..1 normalized `qreal`; the hue / saturation / value /
alpha channels each follow the same independent semantics. The output is
always an integer-component color, writable cleanly as `#RRGGBB`
(opaque) or `#AARRGGBB`.

### Four-channel semantics (preferred lock / random)

- `preferredX >= 0`: the channel is **locked** to `preferredX`, not
  randomized; `minimumX` / `maximumX` are ignored.
- `preferredX < 0` (default `-1`): the channel is randomized within
  `[minimumX, maximumX]` (the min/max are ordered automatically).

Default configuration: hue randomized over the full ring (0..1),
saturation and value over 0.25..1, and alpha **locked to 1** (opaque) —
`preferredAlpha` defaulting to 1 is deliberate: random picking is opaque
by default; a host that wants transparency explicitly releases it
(`< 0` enables alpha randomization).

### 255 quantization (deliberate, do not treat as a bug)

Internally everything is quantized to 0..255 integers (step
360/256 ≈ 1.41°). The quantization granularity pairs with the anti-repeat
constraint ("hue differs by at least 20 from the previous result"; the
other channels are unconstrained uniform random). Making 255 finer or
switching to floating-point construction would break the anti-repeat
semantics — 255 is part of the design, not an implementation detail.

### Hue full-ring mapping (v3 defect fix, integer path)

The hue is generated in the 0..255 quantized domain and mapped to a full
0..359-degree ring with `qRound(hue * 360 / 255) % 360` when constructing
the color, fed to the `int` overload of `QColor::fromHsv`. **Do not**
switch to the `fromHsvF` floating-point construction. The mapped result
255 → 360° ≡ 0°, synonymous with 0 (ring wrap).

v3 defect: the quantized domain 0..255 was fed directly to `fromHsv`
(whose `h` parameter is 0..359), so an input of 1.0 actually covered only
70.8% of the hue ring; and the previous comparison crossed domains
(`hsvHue()` returning 0..359 subtracted directly from the 0..255
quantized domain). The fix: `previous` is uniformly taken in the 255
domain (`hsvHueF() * 255`; an achromatic previous yields `hsvHueF() == -1`
→ no hue constraint that round, the draw passes immediately), and the
full-ring mapping happens at generation time.

### Anti-repeat and lists

- Anti-repeat: only the **hue** channel must differ by ≥ 20 from the
  previous result (sat/value/alpha have no such constraint, uniform
  random).
- When `whiteList` is non-empty, colors are picked from it first (still
  subject to `blackList` and the anti-repeat constraint).
- `blackList` excludes: a color that hits `blackList` is never returned.

### Thread safety

`generate()` serializes internally with a mutex; the `previous` state is
lock-protected and the call may cross threads (the lock is a
`QRecursiveMutex`; the check-and-update of `previous` inside `generate()`
is reentrant).

## Properties

- `minimumHue : real` (default: `0`)
  The hue lower bound (0..1 normalized; the random range lower bound when
  `preferredHue < 0`).

- `maximumHue : real` (default: `1`)
  The hue upper bound (0..1 normalized; the random range upper bound when
  `preferredHue < 0`). Default 1 — the full ring (with the full-ring
  mapping covering all of 0..359 degrees).

- `preferredHue : real` (default: `-1`)
  The locked hue (0..1 normalized). When `>= 0` the hue channel is locked
  to `preferredHue` (min/max ignored); when `< 0` it is randomized. Note
  `1.0` and `0.0` are synonymous (360° ≡ 0°, full-ring wrap).

- `minimumSaturation : real` (default: `0.25`)
  The saturation lower bound (0..1 normalized).

- `maximumSaturation : real` (default: `1`)
  The saturation upper bound (0..1 normalized).

- `preferredSaturation : real` (default: `-1`)
  The locked saturation (0..1 normalized); `>= 0` locks, `< 0`
  randomizes.

- `minimumValue : real` (default: `0.25`)
  The value lower bound (0..1 normalized).

- `maximumValue : real` (default: `1`)
  The value upper bound (0..1 normalized).

- `preferredValue : real` (default: `-1`)
  The locked value (0..1 normalized); `>= 0` locks, `< 0` randomizes.

- `minimumAlpha : real` (default: `0`)
  The alpha lower bound (0..1 normalized).

- `maximumAlpha : real` (default: `1`)
  The alpha upper bound (0..1 normalized).

- `preferredAlpha : real` (default: `1`)
  The locked alpha (0..1 normalized). Defaults to **1** (opaque,
  deliberate) — random picking is opaque by default; `< 0` enables alpha
  randomization within `[minimumAlpha, maximumAlpha]`.

- `previous : color` (read-only, default: `Qt::white`)
  The last successfully generated color. The default `Qt::white` means the
  first `generate()` only has to differ from white.

- `blackList : list<color>` (default: empty)
  The exclusion list: when the generated result hits any of these colors
  it is re-rolled (lower priority than `whiteList` — a whiteList hit that
  is also in `blackList` is still excluded).

- `whiteList : list<color>` (default: empty)
  The whitelist: when non-empty, colors are picked randomly from it first
  (skipping the HSV random construction; still subject to `blackList` and
  the anti-repeat constraint).

## Signals

- `previousChanged()`
  Emitted when a new color becomes `previous` (after a successful
  generation).

- `minimumHueChanged()`, `maximumHueChanged()`, `preferredHueChanged()`,
  `minimumSaturationChanged()`, `maximumSaturationChanged()`,
  `preferredSaturationChanged()`, `minimumValueChanged()`,
  `maximumValueChanged()`, `preferredValueChanged()`,
  `minimumAlphaChanged()`, `maximumAlphaChanged()`,
  `preferredAlphaChanged()`, `blackListChanged()`, `whiteListChanged()`
  Per-property NOTIFY signals for the writable properties above.

## Methods

- `color generate()`
  Generates a color satisfying the current constraints. The result: not in
  `blackList`, different from the previous `generate()` result (hue
  channel difference ≥ 20; sat/value/alpha unconstrained random), and any
  channel with `preferred >= 0` keeps its locked value. On the first call
  `previous` is default white, so the result only has to differ from
  white.

- `int count()`
  Returns the number of distinct combinations under the current
  configuration: the product of per-channel interval widths (in
  255-quantized units; locked channels count 0) plus 1. With the default
  configuration (alpha locked) it returns 1.

## Usage Example

```qml
import QtQuick
import Qool.Color

RandomHSVColorGenerator {
    id: generator
    // Defaults: full hue ring, sat/value 0.25..1, alpha locked opaque.
    // minimumHue: 0; maximumHue: 1; preferredHue: -1
}

Rectangle {
    color: generator.generate()
    onColorChanged: console.log("hue guard: next differs by >= 20")
}

// Constrain and lock channels.
RandomHSVColorGenerator {
    minimumSaturation: 0.5
    maximumSaturation: 0.8
    preferredValue: 1.0     // locked to full value
    blackList: ["#ff0000"]
}
```
