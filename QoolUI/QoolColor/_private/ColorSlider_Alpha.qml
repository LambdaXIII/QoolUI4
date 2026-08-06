// NOTE(迁移) v3 Qool.Color/_private/ColorSlider_Alpha.qml 逐字迁移。
// 关键行为（勿改）：
//   - 渐变从 transparent（position 0）到 displayColor（position 1）——
//     displayColor 是 colorAssistant.solidColor（去 alpha 的当前色），
//     即"当前颜色从不透明到透明"的示意。
//   - 双向绑定 alphaF，交互期写 / 非交互期同步（两个互斥 Binding，v3 原样）。
//   - 双击重置 defaultValue = 1。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

/*!
    \qmltype ColorSlider_Alpha
    \inqmlmodule Qool.Color
    \brief 透明度滑块（v3 逐字迁移）：当前色 → 透明渐变轨道，双向绑定 alphaF。

    \section2 易误解点
    \list
    \li 渐变终点是 \c displayColor（= colorAssistant.solidColor）而非纯色常量——
        通道色变化时渐变随之变化，勿改成固定颜色。
    \li \c displayColor 语义与 Value 滑块相同（去 alpha 的当前色），
        但本滑块控制的是 alphaF 本身。
    \endlist
*/
ColorSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "ALPHA"
    defaultValue: 1
    displayColor: colorAssistant.solidColor

    fillGradient: LinearGradient {
        x1: leftPoint.x
        x2: rightPoint.x
        y1: leftPoint.y
        y2: rightPoint.y
        GradientStop {
            position: 0
            color: "transparent"
        }
        GradientStop {
            position: 1
            color: displayColor
        }
    }

    strokeColor: colorAssistant.recommendedForegroundColor

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: colorAssistant.alphaF
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "alphaF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }
}
