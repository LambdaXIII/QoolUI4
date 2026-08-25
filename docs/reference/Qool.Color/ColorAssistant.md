# ColorAssistant

A multi-color-space color object: writing any component in any space
synchronizes all spaces.

`ColorAssistant` holds a single color and exposes RGB / CMYK / HSV / HSL
component properties (in both `int` and float dual tracks) plus list
properties. Writing any component recomputes all spaces and broadcasts
all `Changed` signals.

### Dual-track components

The `int` and float (`F`-suffixed) tracks run in parallel, are
semantically identical and stay in sync: the float versions are 0..1
normalized (`redF` and friends), the `int` versions are 0..255 (`red`,
`hsvValue`, …) with hue in 0..359 (`hsvHue`, `hslHue`). The float track
serves continuous interaction (panel sliders, gradients); the `int` track
is part of the public API surface. Neither is redundant — writing either
track goes through the unified `color` setter, which recomputes every
space.

### Derived read-only properties

`solidColor` (alpha stripped), `visualBrightness` (0.299/0.587/0.114
weighted luminance) and `recommendedForegroundColor` (black/white contrast
foreground at the 0.5 luminance threshold) update with `color`. The
luminance formula matches `ThemeHQ`; because v4 C++ classes are not
dynamically exported and QML exposure goes through the type system, the
derived values are implemented internally rather than delegated across
modules.

### Alpha semantics

Both write paths preserve the current alpha unless the input carries an
explicit alpha entry:

- **Component setters preserve the current alpha**: they rebuild the
  color in the component's space with the existing alpha carried over —
  editing a single channel never changes opacity.
- **List writes without an alpha slot preserve it too**: `cmykF` /
  `cmyk` / `hsvF` / `hsv` / `hslF` / `hsl` rebuild the color via the
  `QColor` factory, then carry the current alpha over. All six lists
  behave identically — writing color components never changes opacity.
- `rgbaF` / `rgba` carry an explicit alpha entry (the 4th element);
  writing a 4-entry list sets it directly; a shorter list leaves the
  current alpha untouched.

`solidColor` is the explicit way to obtain an opaque variant.

### Zero-alpha channel retention

Setting the alpha to zero through any write path (`alphaF`/`alpha`, or
the 4th element of `rgbaF`/`rgba`) makes the color fully transparent
but does **not** discard the RGB channels — a deliberate difference
from the CSS-style expectation where "transparent" equals
`rgba(0, 0, 0, 0)`. Raising the alpha again restores exactly the
previous color. The retention holds across every read surface while
the color is fully transparent: `solidColor` yields the opaque variant
of the retained channels, and `name()` keeps reporting them in
`#AARRGGBB` form (e.g. `#00334d80` for `rgba(0.2, 0.3, 0.5)` at alpha
0).

Only writing the string literal `"transparent"` (or an explicit
`#00000000`) actually zeroes the channels — that loss happens in input
parsing before the value reaches the object, so raising the alpha
afterwards yields black.

Out-of-range writes behave differently per entry type:

- **RGB and alpha components** (`redF`/`greenF`/`blueF`/`alphaF` and the
  integer `red`/`green`/`blue`/`alpha`) are clamped into range ([0, 1]
  float / [0, 255] integer): the underlying `QColor` channel setters clip
  these values instead of rejecting them.
- **HSV / HSL components** (both tracks) are normalized/clamped into
  range under the channel-anchoring model: hue wraps modulo into [0, 1)
  (−0.5 → 0.5, 1.5 → 0.5, 360° → 0°), the other components clamp to
  [0, 1]; the color always stays valid.
- **CMYK components** (both tracks) are passed straight to the `QColor`
  setters; an out-of-range value invalidates the whole color instead of
  being clamped.
- **List writes** go through the `QColor::fromXxx` factories, whose
  parameter domains differ per space:

  - `rgba` rejects any entry outside 0..255 and invalidates the color.
  - `rgbaF` accepts floats outside [0, 1] as extended-RGB values (the
    color stays valid); the component views report the values converged
    back into [0, 1].
  - `hsv` / `hsvF` / `hsl` / `hslF` normalize/clamp entries like the
    component setters (hue wraps, others clamp; the color stays valid).
  - `cmyk` / `cmykF` invalidate the color on any out-of-range entry.

An invalidated color does not brick the object: a subsequent in-range
write through any entry recomputes a valid color as usual.

### Channel anchoring (ADR-0020)

The authoritative representation is the RGB color; the HSV/HSL views are
derived. Dimensions with no expression in the current color (the
*achromatic axes*) are *anchored* instead of collapsed:

- **Anchor update, three branches**: an explicit component/list write
  always lands on the anchor — the written value is remembered even when
  the resulting color has no expression for that dimension; a derived
  value overwrites the anchor only when the dimension is expressed; an
  unexpressed dimension freezes the anchor at its last value.
- **Freeze table**: hue freezes when the derived hue is negative (gray
  axis — hsv saturation 0 or value 0; hsl saturation 0 or lightness
  ∈ {0, 1}); `hsvSaturation` freezes when value is 0 (black axis);
  `hslSaturation` freezes when lightness ∈ {0, 1} (black/white axes).
  `value` / `lightness` are always expressed and always follow the true
  conversion.
- **Anchors are the public readings**: `hsvHueF` / `hslHueF` and the
  integer `hsvHue` / `hslHue` always report a value in [0, 1) / [0, 359] —
  `-1` is retired. Achromatic colors are judged by
  `valueF == 0 || saturationF == 0` (HSV) or
  `lightnessF ∈ {0, 1} || saturationF == 0` (HSL), never by a negative
  hue. The integer tracks derive from the anchored float members
  (`qRound(x * 360) % 360` for hue, `qRound(x * 255)` otherwise), so both
  tracks stay consistent on gray axes.
- **Shared hue anchor**: HSV and HSL hue are the same mathematical
  quantity (the RGB chroma angle) — they share a single anchor; writing
  either keeps both in sync and emits both `Changed` signals.
- **Rebuild from members**: component and list setters reconstruct the
  candidate color from the member values
  (`QColor::fromHsvF(m_hsvHueF, …)`), never by reading the current color
  back through `toHsv()`/`toHsl()` (that readback was the collapse
  source). On chromatic colors the float readings follow the true
  conversion (8-bit quantization round-trip), so an explicit hue write
  reports the color's actual hue rather than the request; on achromatic
  colors the frozen anchor is reported as written.

## Properties

- `color : color` (NOTIFY `colorChanged`)
  The single color held by the object. All other properties are derived
  views of this value.

- `rgbaF : list<real>`, `cmykF : list<real>`, `hsvF : list<real>`, `hslF :
  list<real>` (NOTIFY `rgbaFChanged`/`cmykFChanged`/`hsvFChanged`/`hslFChanged`)
  Float track list views: `[r, g, b, a]`, `[c, m, y, k]`, `[h, s, v]`,
  `[h, s, l]`, all 0..1. Writing a list rebuilds the color from its
  space, using the current components as defaults for missing entries.

- `rgba : list<int>`, `cmyk : list<int>`, `hsv : list<int>`, `hsl :
  list<int>` (NOTIFY `rgbaChanged`/`cmykChanged`/`hsvChanged`/`hslChanged`)
  Integer track list views with the same layout semantics, in 0..255
  (hue 0..359).

- `name : string` (NOTIFY `nameChanged`)
  The color as a string, dynamically generated: `#AARRGGBB` when the
  alpha is below 1, otherwise `#RRGGBB`. Writing parses the string via
  `QColor::fromString`; an unparseable string makes the color invalid
  (`isValid()` becomes `false`, a debug warning is logged).

- `solidColor : color` (read-only, NOTIFY `colorChanged`)
  The color with alpha forced to 1.

- `visualBrightness : real` (read-only, NOTIFY `colorChanged`)
  The perceived luminance, `0.299 * r + 0.587 * g + 0.114 * b` over the
  RGB channels.

- `recommendedForegroundColor : color` (read-only, NOTIFY `colorChanged`)
  The contrast foreground: black when `visualBrightness >= 0.5`, white
  otherwise.

- Float components, 0..1 (each NOTIFYs its own `xxxChanged`):
  `redF`, `greenF`, `blueF`, `alphaF`, `cyanF`, `magentaF`, `yellowF`,
  `blackF`, `hsvHueF`, `hsvSaturationF`, `hsvValueF`, `hslHueF`,
  `hslSaturationF`, `hslLightnessF`.

- Integer components (each NOTIFYs its own `xxxChanged`):
  `red`, `green`, `blue`, `alpha`, `cyan`, `magenta`, `yellow`, `black`
  (0..255); `hsvHue`, `hslHue` (0..359); `hsvSaturation`, `hsvValue`,
  `hslSaturation`, `hslLightness` (0..255).

  Hue is always valid: on achromatic colors (gray axis) the hue anchors
  freeze at their last value (initial `0`) instead of collapsing to `-1`
  — the hue readings stay in [0, 1) / [0, 359] in both tracks, and
  achromaticity is judged by `valueF == 0 || saturationF == 0` (see
  Channel anchoring). Hue written outside the domain is normalized
  modulo into range on every entry type (360° → 0°, −0.5 → 0.5).

## Signals

- `colorChanged()`
  Emitted when the color actually changes (after the full-space
  recomputation). Also serves as the NOTIFY for the derived read-only
  properties.

- `rgbaFChanged()`, `cmykFChanged()`, `hsvFChanged()`, `hslFChanged()`,
  `rgbaChanged()`, `cmykChanged()`, `hsvChanged()`, `hslChanged()`,
  `nameChanged()`
  Emitted together with `colorChanged` whenever the underlying color
  changes.

- `redFChanged()`, `greenFChanged()`, `blueFChanged()`, `alphaFChanged()`,
  `redChanged()`, `greenChanged()`, `blueChanged()`, `alphaChanged()`,
  `cyanFChanged()`, `magentaFChanged()`, `yellowFChanged()`,
  `blackFChanged()`, `cyanChanged()`, `magentaChanged()`,
  `yellowChanged()`, `blackChanged()`, `hsvHueFChanged()`,
  `hsvSaturationFChanged()`, `hsvValueFChanged()`, `hsvHueChanged()`,
  `hsvSaturationChanged()`, `hsvValueChanged()`, `hslHueFChanged()`,
  `hslSaturationFChanged()`, `hslLightnessFChanged()`, `hslHueChanged()`,
  `hslSaturationChanged()`, `hslLightnessChanged()`
  Per-component NOTIFY signals; emitted (with `colorChanged`) when the
  recomputed component actually differs from its previous value.

## Methods

- `static string hex(int number)`
  Returns the integer as a lowercase hexadecimal string; the `#` prefix is
  left to the caller.

- `static bool isValidName(string name)`
  Returns whether the string is a valid color name, via
  `QColor::isValidColorName`: any SVG color keyword ("red",
  "steelblue", …), `transparent`, or one of the hex forms
  `#RGB` / `#RRGGBB` / `#AARRGGBB` / `#RRRGGGBBB` / `#RRRRGGGGBBBB`.

  `static` methods are exposed on the type, but the type name carries no
   method surface in QML — call them through an instance
  (`assistant.hex(255)`, `assistant.isValidName("red")`).

- `bool isValid()`
  Returns whether the current color is valid (false before a valid color
  has been set).

## QML 扩展：ColorLiterals

 `ColorAssistant` **不挂** `QML_EXTENDED(ColorLiterals)`——此前保留的
共享通道字面量已整体让渡给 `ColorHQ` 单例。因此通道字面量
（`Channels` 枚举、`channelNameF` 等通道工具方法）只能经 `ColorHQ`
访问：`ColorHQ.Channels.Red`、`ColorHQ.channelNameF(...)`——singleton
类型名即实例，模块内组件与宿主均用 `ColorHQ`。
`ColorAssistant` 只保留自身 `Q_INVOKABLE`：`hex`/`isValidName`/`isValid`
（经实例调用）。
通道枚举值即 `ColorChannelSlider.channel` 等接口的取值域。

### 枚举 `Channels`

`Alpha` (0)、`Red` (1)、`Green` (2)、`Blue` (3)、`HSVHue` (4)、
`HSVSaturation` (5)、`HSVValue` (6)、`HSLHue` (7)、`HSLSaturation` (8)、
`HSLLightness` (9)、`Cyan` (10)、`Magenta` (11)、`Yellow` (12)、
`Black` (13)。

 ### 静态方法

> 以下方法经 `ColorHQ` 单例访问（`ColorHQ.channelName(...)` 等）；
> `ColorAssistant` 自身不暴露这些方法。

- `static string channelName(int channel)` — 通道属性名（"red"、
  "hsvHue"、…；hue 类返回无 `F` 后缀名）。
- `static string channelNameF(int channel)` — F 轨属性名
  （`channelName` 结果追加 `"F"`）。
- `static string channelTag(int channel)` — 外观标签长文本
  （"RED"、"SATURATION"、…）。
- `static string channelTagShort(int channel)` — 外观标签短文本
  （"RED"、"SAT"、"BRIT"、"LIT"、"BLAK"、…）。
- `static color channelColor(int channel)` — 通道代表色；未定义通道
  返回 `transparent`（Hue/Saturation 类通道无代表色）。
- `static string formatChannelNumberFloat(real num)` — 归一化通道值
  格式化，仅四种输出：`"0"`、`"1"`、`".xxx"`（三位小数无前导零）、
  `"NaN"`。
- `static real parseChannelNumberFloat(string input)` — 归一化通道值
  解析（`formatChannelNumberFloat` 的反向）：清洗输入（仅保留数字与
  第一个小数点）→ 无小数点时头部补点（整数按纯小数解释，
  `"350"` → `.350` → 0.35）→ 解析；失败返回 `NaN`。
- `static real clampChannelRange(real x)` — 钳制到 [0, 1]。

## Usage Example

```qml
import QtQuick
import Qool
import Qool.Color

ColorAssistant {
    id: assistant
    color: Style.highlight
}

// One shared assistant keeps every panel synchronized.
RGBPanel  { colorAssistant: assistant }
CMYKPanel { colorAssistant: assistant }

// Component access: the int and float tracks stay in sync.
Text {
    text: assistant.name
    color: assistant.recommendedForegroundColor
}

// List-style access and hex conversion.
Text {
    text: "0x" + assistant.hex(assistant.red)
}
```
