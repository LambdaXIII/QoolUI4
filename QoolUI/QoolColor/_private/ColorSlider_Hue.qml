// 关键行为与易误解点（最易被当 bug 修）：
//   1. 无效色相特殊处理：用户拖动期间（Connections enabled: userInteracting，
//      target 默认 = root 自身，onValueChanged 监听 root.valueChanged），
//      若 colorAssistant.hsvHueF < 0（ColorAssistant 对"无色相"色返回负 hue，
//      如纯灰/黑/白），先把 hsvSaturationF 写到 0.001 再写 hue——
//      因为 sat=0 时色相无意义、直接写 hue 不会产生预期颜色，0.001 保住
//      "有饱和度的色相"语义。这是刻意设计，勿删/勿改为 0。
//   2. 非交互时（!userInteracting）由 hsvHueFChanged 反向同步 value，且经
//      CycleBetweenEdges 环绕（hue 越出 [0,1] 时环绕到 [min-1, max-1] 区间，
//      实数 cycle 含 -1 修正）。
//   3. 渐变是 11 档彩虹（0..1 每 0.1 一档，hsva(position, 1, 1, 1)），
//      锚定 leftPoint/rightPoint（ColorSliderBackground 的渐变锚点）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

// 色相滑块：彩虹渐变轨道 + 环绕式数值同步。
//
// `colorAssistant` 为通道数据源（默认自带 ColorAssistant{}）。交互期间
// 写 `hsvHueF`，非交互期间由 `hsvHueFChanged` 反向同步 `value`。
//
// 易误解点
// - 无效色相特殊处理（`hsvHueF` < 0 → 先写 `hsvSaturationF` = 0.001）：
//   详见文件头注释 1，这是刻意设计。
// - `value` 经 CycleBetweenEdges 环绕（含 -1 修正）——hue 短暂越界时
//   环绕而非裁剪。
// - 双击重置：value → defaultValue（0），与 Value/Alpha 的 1 不同。
ColorSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "HUE"
    defaultValue: 0
    value: colorAssistant.hsvHueF
    displayColor: colorAssistant.solidColor

    fillGradient: LinearGradient {
        x1: leftPoint.x
        x2: rightPoint.x
        y1: leftPoint.y
        y2: rightPoint.y
        GradientStop {
            position: 0
            color: Qt.hsva(0, 1, 1, 1)
        }
        GradientStop {
            position: 0.1
            color: Qt.hsva(0.1, 1, 1, 1)
        }
        GradientStop {
            position: 0.2
            color: Qt.hsva(0.2, 1, 1, 1)
        }
        GradientStop {
            position: 0.3
            color: Qt.hsva(0.3, 1, 1, 1)
        }
        GradientStop {
            position: 0.4
            color: Qt.hsva(0.4, 1, 1, 1)
        }
        GradientStop {
            position: 0.5
            color: Qt.hsva(0.5, 1, 1, 1)
        }
        GradientStop {
            position: 0.6
            color: Qt.hsva(0.6, 1, 1, 1)
        }
        GradientStop {
            position: 0.7
            color: Qt.hsva(0.7, 1, 1, 1)
        }
        GradientStop {
            position: 0.8
            color: Qt.hsva(0.8, 1, 1, 1)
        }
        GradientStop {
            position: 0.9
            color: Qt.hsva(0.9, 1, 1, 1)
        }
        GradientStop {
            position: 1
            color: Qt.hsva(1, 1, 1, 1)
        }
    }

    strokeColor: colorAssistant.recommendedForegroundColor

    Connections {
        enabled: root.userInteracting
        target: root
        function onValueChanged() {
            if (colorAssistant.hsvHueF < 0)
                colorAssistant.hsvSaturationF = 0.001
            colorAssistant.hsvHueF = root.value
        }
    }

    QtObject {
        id: limiter
        // CycleBetweenEdges [0,1] 环绕式限幅。
        function limit(x) {
            return _limit_cycle_real(x, 0, 1)
        }

        // 实数 cycle 环绕实现：distance 不含 +1、末尾 -1 以包含最小值。
        // 数值上异于直觉的边界是刻意行为，勿改。
        function _limit_cycle_real(value, min, max) {
            if (min === max)
                return min
            const lo = Math.min(min, max)
            const hi = Math.max(min, max)
            if (value >= lo && value <= hi)
                return value
            const distance = Math.abs(hi - lo)
            const offset = value - lo
            const _x = offset / distance
            let fixed = offset - Math.trunc(_x) * distance
            if (fixed < 0)
                fixed += distance
            return lo + fixed - 1 // -1 以包含最小值
        }
    }

    Connections {
        enabled: !root.userInteracting
        target: root.colorAssistant
        function onHsvHueFChanged() {
            root.value = limiter.limit(root.colorAssistant.hsvHueF)
        }
    }
}
