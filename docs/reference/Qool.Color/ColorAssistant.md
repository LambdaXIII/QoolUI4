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

Component setters preserve the current alpha (they rebuild the color in
the component's space with the existing alpha carried over). List writes
differ by space:

- `rgbaF` / `rgba` carry an explicit alpha entry; writing a 4-entry list
  sets it.
- `cmykF` / `cmyk` / `hsvF` / `hsv` / `hslF` have no alpha slot — writing
  them resets alpha to opaque (1 / 255).
- `hsl` (integer track) is the exception: it preserves the current alpha.

`solidColor` is the explicit way to obtain an opaque variant.

Out-of-range writes behave differently per space:

- RGB float components (`redF`/`greenF`/`blueF`) are clamped to [0, 1]:
  the underlying `QColor` stores them as ExtendedRgb and the unified
  `toRgb()` recomputation converges them.
- HSV / HSL / CMYK components (both tracks) are passed straight to the
  `QColor` setter; out-of-range values make the color invalid instead of
  clamping. The `int` hue tracks keep their wrap semantics (360 → 0,
  540 → 180) since `QColor` forces them into range.

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

  Achromatic colors (grays) report hue as `-1` in both tracks
  (`hsvHue`/`hsvHueF`/`hslHue`/`hslHueF`). Hue values written outside
  0..359 are forced into range by the underlying `QColor` (360 → 0,
  540 → 180).

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
  (`assistant.hex(255)`, `assistant.isValidName("red")`). The same applies
  to the `ColorLiterals` extension methods below.

- `bool isValid()`
  Returns whether the current color is valid (false before a valid color
  has been set).

## QML 扩展：ColorLiterals

`ColorAssistant` 通过 `QML_EXTENDED(ColorLiterals)` 暴露通道字面量与
通道工具方法。枚举经类型名访问（`ColorAssistant.Channels`——
`QML_EXTENDED` 把枚举附加到类型名）；方法（`channelName` 等）与
`hex`/`isValidName` 一样经**实例**调用（类型名无方法面，探针实证）。
同一扩展也挂在 `ColorNameHQ` 单例上——singleton 类型名即实例，
`ColorNameHQ.channelNameF(...)` 等价可用（模块内组件实际用后者）。
通道枚举值即 `ColorChannelSlider.channel` 等接口的取值域。

### 枚举 `Channels`

`Alpha` (0)、`Red` (1)、`Green` (2)、`Blue` (3)、`HSVHue` (4)、
`HSVSaturation` (5)、`HSVValue` (6)、`HSLHue` (7)、`HSLSaturation` (8)、
`HSLLightness` (9)、`Cyan` (10)、`Magenta` (11)、`Yellow` (12)、
`Black` (13)。

### 静态方法

- `static string channelName(int channel)` — 通道属性名（"red"、
  "hsvHue"、…；hue 类返回无 `F` 后缀名）。
- `static string channelNameF(int channel)` — F 轨属性名
  （`channelName` 结果追加 `"F"`）。
- `static string channelTag(int channel)` — 外观标签长文本
  （"RED"、"SATURATION"、…）。
- `static string channelTagShort(int channel)` — 外观标签短文本
  （"RED"、"SAT"、"VAL"、"LIT"、"BLAK"、…）。
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
