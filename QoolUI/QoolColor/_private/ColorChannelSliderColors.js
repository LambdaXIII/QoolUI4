.pragma library

// 水平族轨道渐变端点映射（数据决策，勿改）：
//   - RGB：黑 → 纯通道色（通道贡献从无到有）
//   - HSVValue / HSLLightness：黑 → 白
//   - CMYK：白 → 纯通道色（墨量 0 = 纸白）
//   - Alpha：transparent → assistant.solidColor
//   - HSVSaturation：灰(当前亮度) → hsva(hue, 1, value)——原理式（轨道
//     每位置 = 改 sat 后真实结果色）
//   - HSLSaturation：同理 hsla(hue, 1, lightness)
//   - Hue 两通道不在本表——彩虹特化（TrackHue 自带 11 档渐变）

// 通道常量镜像 qool_colorliterals.h ColorLiterals::Channels 枚举序——
// 改动枚举必须同步本表（渐变端点测试锚定此表）。
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

// 无色相（hue = -1）回退 0（红相）——防 Qt.hsva 负 hue 构造垃圾色
function validHue(hue) {
    return hue >= 0 ? hue : 0
}

function fromColor(channel, assistant) {
    switch (channel) {
    case RED:
    case GREEN:
    case BLUE:
    case HSV_VALUE:
    case HSL_LIGHTNESS:
        return Qt.rgba(0, 0, 0, 1)
    case CYAN:
    case MAGENTA:
    case YELLOW:
    case BLACK:
        return Qt.rgba(1, 1, 1, 1)
    case ALPHA:
        return Qt.rgba(0, 0, 0, 0)
    case HSV_SATURATION:
        return Qt.hsva(validHue(assistant.hsvHueF), 0, assistant.hsvValueF, 1)
    case HSL_SATURATION:
        return Qt.hsla(validHue(assistant.hslHueF), 0, assistant.hslLightnessF, 1)
    }
    return Qt.rgba(0, 0, 0, 1)
}

function toColor(channel, assistant) {
    switch (channel) {
    case RED:
        return Qt.rgba(1, 0, 0, 1)
    case GREEN:
        return Qt.rgba(0, 1, 0, 1)
    case BLUE:
        return Qt.rgba(0, 0, 1, 1)
    case HSV_VALUE:
    case HSL_LIGHTNESS:
        return Qt.rgba(1, 1, 1, 1)
    case CYAN:
        return Qt.rgba(0, 1, 1, 1)
    case MAGENTA:
        return Qt.rgba(1, 0, 1, 1)
    case YELLOW:
        return Qt.rgba(1, 1, 0, 1)
    case BLACK:
        return Qt.rgba(0, 0, 0, 1)
    case ALPHA:
        return assistant.solidColor
    case HSV_SATURATION:
        return Qt.hsva(validHue(assistant.hsvHueF), 1, assistant.hsvValueF, 1)
    case HSL_SATURATION:
        return Qt.hsla(validHue(assistant.hslHueF), 1, assistant.hslLightnessF, 1)
    }
    return Qt.rgba(1, 1, 1, 1)
}

// 渐变锚定几何（轨道 Crystal 切角内有效段 + 值增大视觉端）：
//   - 水平：from 端 = 值小端——LTR 左、RTL（mirrored）右（stop 色序不变，
//     position 0 = from 色随坐标移动）
//   - 垂直：恒 from 底 → to 顶（Qt 垂直惯例——visualPosition 恒
//     1−position，不受 RTL 影响，故不对调）
// 坐标空间 = 轨道 Crystal 局部空间——调用方传轨道自身宽高。
function gradientAnchors(width, height, horizontal, mirrored) {
    const cut = Math.min(width, height) / 2
    if (horizontal) {
        return {
            x1: mirrored ? width - cut : cut,
            y1: height / 2,
            x2: mirrored ? cut : width - cut,
            y2: height / 2
        }
    }
    return {
        x1: width / 2,
        y1: height - cut,
        x2: width / 2,
        y2: cut
    }
}
