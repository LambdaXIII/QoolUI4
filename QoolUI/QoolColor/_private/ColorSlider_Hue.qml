// NOTE(迁移) v3 Qool.Color/_private/ColorSlider_Hue.qml 逐字迁移。
// 拍平点：v3 的 NumberLimiter(min:0, max:1, mode:CycleBetweenEdges) 内联为
// 本文件 limiter（_limit_cycle_real 与 v4 CycleChoice 内联版同源，语义与 v3
// x3_number_tools 实数 cycle 逐字一致，含末尾 -1 修正——勿改）。
//
// 关键行为与易误解点（spec §7-9，最易被当 bug 修）：
//   1. 无效色相特殊处理：用户拖动期间（Connections enabled: userInteracting，
//      target 默认 = root 自身，onValueChanged 监听 root.valueChanged），
//      若 colorAssistant.hsvHueF < 0（ColorAssistant 对"无色相"色返回负 hue，
//      如纯灰/黑/白），先把 hsvSaturationF 写到 0.001 再写 hue——
//      因为 sat=0 时色相无意义、直接写 hue 不会产生预期颜色，0.001 保住
//      "有饱和度的色相"语义。这是刻意设计，勿删/勿改为 0。
//   2. 非交互时（!userInteracting）由 hsvHueFChanged 反向同步 value，且经
//      CycleBetweenEdges 环绕（hue 越出 [0,1] 时环绕到 [min-1, max-1] 区间，
//      v3 实数 cycle 含 -1 修正的逐字行为）。
//   3. 渐变是 11 档彩虹（0..1 每 0.1 一档，hsva(position, 1, 1, 1)），
//      锚定 leftPoint/rightPoint（ColorSliderBackground 的渐变锚点）。
// 与 v3 的刻意差异：无（仅 NumberLimiter 内联 + Style 对位 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

/*!
    \qmltype ColorSlider_Hue
    \inqmlmodule Qool.Color
    \brief 色相滑块（v3 逐字迁移）：彩虹渐变轨道 + 环绕式数值同步。

    \c colorAssistant 为通道数据源（默认自带 ColorAssistant{}）。交互期间
    写 \c hsvHueF，非交互期间由 \c hsvHueFChanged 反向同步 \c value。

    \section2 易误解点
    \list
    \li 无效色相特殊处理（\c hsvHueF < 0 → 先写 \c hsvSaturationF = 0.001）：
        详见文件头注释 1，这是 spec §7-9 明示的刻意设计。
    \li \c value 经 CycleBetweenEdges 环绕（含 -1 修正）——hue 短暂越界时
        环绕而非裁剪，是 v3 实数 cycle 的逐字行为。
    \li 双击重置：value → defaultValue（0），与 Value/Alpha 的 1 不同。
    \endlist
*/
ColorSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: qsTr("HUE")
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
        // v3 NumberLimiter(min:0, max:1, mode:CycleBetweenEdges) 内联。
        function limit(x) {
            return _limit_cycle_real(x, 0, 1)
        }

        // v3 NumberLimiter::keepBetweenEdges（x3_number_tools 实数 cycle）逐字内联：
        // distance 不含 +1、末尾 -1 以包含最小值。语义与 v3 完全一致——
        // 数值上异于直觉的边界是 v3 原行为，勿改。
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
            return lo + fixed - 1 // -1 以包含最小值（v3 注释原样）
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
