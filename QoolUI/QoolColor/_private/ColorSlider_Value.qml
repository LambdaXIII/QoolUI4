// NOTE(迁移) v3 Qool.Color/_private/ColorSlider_Value.qml 逐字迁移。
// 关键行为（勿改）：
//   - 双向绑定用两个互斥 Binding（when 切换）：userInteracting 时写
//     colorAssistant.hsvValueF，否则从 hsvValueF 同步 root.value。
//     restoreMode: Binding.RestoreNone（v3 原样）——交互态切换时值不回滚。
//   - 渐变是竖直渐变（黑 → 白），注意 position 1 在上（白色）：
//     "value" 滑块语义 = HSV 明度，顶端最亮，与直觉方向相反，v3 原样。
//   - 双击重置 defaultValue = 1。
// 与 v3 的刻意差异：无（仅注释；Style/依赖对位见 ColorSlider 基类头注释）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

// 明度滑块（v3 逐字迁移）：黑→白渐变轨道，双向绑定 hsvValueF。
//
// 易误解点
// - 渐变方向：position 1 是白色（顶部）——明度滑块"上亮下暗"，与直觉相反，
//   是 v3 原样；改方向会与 ColorAssistant.hsvValueF 语义错位。
// - 交互期写 hsvValueF、非交互期从 hsvValueF 同步，靠两个互斥 Binding
//   完成（v3 惯用法，与 Hue 的 Connections 方案不同但等价）。
ColorSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "VALUE"
    defaultValue: 1
    displayColor: colorAssistant.solidColor

    fillGradient: LinearGradient {
        x1: leftPoint.x
        x2: rightPoint.x
        y1: leftPoint.y
        y2: rightPoint.y
        GradientStop {
            position: 1
            color: "white"
        }
        GradientStop {
            position: 0
            color: "black"
        }
    }

    strokeColor: colorAssistant.recommendedForegroundColor

    Binding {
        when: !userInteracting
        target:root
        property:"value"
        value: colorAssistant.hsvValueF
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "hsvValueF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }
}
