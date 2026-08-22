.pragma library

// 竖直族身份色/采样色映射（数据决策，勿改——字面量逐字保留原竖直变体）：
//   - RGB：纯通道色；Green 为 Qt 命名色 "green"（#008000）——勿按水平族
//     纯绿 #00ff00 推断
//   - HSVValue / HSLLightness：white（原 Brightness 语义）
//   - CMYK：纯通道色；Black 为 "darkgrey"（深色主题下纯黑填充不可见，
//     刻意选择，勿"修正"）
//   - Alpha：grey（原 Alpha 语义）
//   - HSVSaturation：hsva(hue, 1, value)——原理式（改 sat 后真实结果色）
//   - HSLSaturation：同理 hsla(hue, 1, lightness)
//   - hue 两通道（HSVHue/HSLHue）不进 identityColor（走 sampleHueColor
//     彩虹特化），兜底返回 white

// 通道常量镜像 qool_colorliterals.h ColorLiterals::Channels 枚举序——
// 改动枚举必须同步本表（与 ColorChannelSliderColors.js 同表，双处维护）。
const ALPHA = 0
const RED = 1
const GREEN = 2
const BLUE = 3
const HSV_HUE = 4
const HSV_SATURATION = 5
const HSV_VALUE = 6
const HSL_HUE = 7
const HSL_SATURATION = 8
const HSL_LIGHTNESS = 9
const CYAN = 10
const MAGENTA = 11
const YELLOW = 12
const BLACK = 13

// 无色相（hue = -1）回退 0（红相）——防 Qt.hsva/hsla 负 hue 构造垃圾色
function validHue(hue) {
    return hue >= 0 ? hue : 0
}

// 身份色（非 hue 通道的填充/bg/border 基色）——字面量逐字保留原变体
function identityColor(channel, assistant) {
    switch (channel) {
    case RED:  return "red"
    case GREEN: return "green"     // Qt 命名色 #008000，勿按水平族纯绿 #00ff00
    case BLUE: return "blue"
    case CYAN: return "cyan"
    case MAGENTA: return "magenta"
    case YELLOW: return "yellow"
    case BLACK: return "darkgrey"  // 非 "black"（深色主题不可见，刻意）
    case ALPHA: return "grey"
    case HSV_VALUE:
    case HSL_LIGHTNESS: return "white"
    case HSV_SATURATION:
        return Qt.hsva(validHue(assistant.hsvHueF), 1, assistant.hsvValueF, 1)
    case HSL_SATURATION:
        return Qt.hsla(validHue(assistant.hslHueF), 1, assistant.hslLightnessF, 1)
    }
    return "white"  // hue 两通道走彩虹特化，兜底
}

// hue 采样色（填充/border 基色，随 value 变化）——原理式跟随当前
// sat/value 或 sat/lightness（轨道每位置 = 把 hue 改为 p 后的真实结果色）
function sampleHueColor(channel, assistant, value) {
    if (channel === HSV_HUE)
        return Qt.hsva(value, assistant.hsvSaturationF, assistant.hsvValueF, 1)
    if (channel === HSL_HUE)
        return Qt.hsla(value, assistant.hslSaturationF, assistant.hslLightnessF, 1)
    return "white"
}

// hue 正常色（填充前景基色，随 value 变化）——固定 sat/lightness = 1 的
// 纯色相色（用户定案 2026-08-23：填充显示色相"正常值"，明暗由背景彩虹
// 承载；与 sampleHueColor 有意分叉）
function hueNormalColor(channel, value) {
    if (channel === HSV_HUE)
        return Qt.hsva(value, 1, 1, 1)
    if (channel === HSL_HUE)
        return Qt.hsla(value, 1, 1, 1)
    return "white"
}
