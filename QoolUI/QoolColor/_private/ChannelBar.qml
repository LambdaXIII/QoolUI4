// NOTE(迁移) v3 Qool.Color/_private/ChannelBar.qml 逐字迁移。
// 依赖替换：QtQuick.Controls.Control → QtQuick.Templates.T.Control
// （模块内不 import Controls，NumInput/CycleChoice 同惯例）；
// v3 未使用的 QtQuick.Shapes import 删除。
// Style 对位：Style.animationEnabled → root.Style.animationEnabled。
//
// 关键行为与易误解点（勿改）：
//   - 填充自底部向上（fillRect.y = parent.height - height，height =
//     parent.height * value），渐变 alpha 0.9（底）→ 0.1（顶）；
//     底色 bgRect 为 channelColor 的 alpha 0.1。
//   - 圆角 = max(0, radius - padding)（内缩 padding 后圆角），radius 默认 5、
//     padding 默认 4 → 1。
//   - movementTimer：fillRect 高度每次变化（onHeightChanged）都重启 1s 计时，
//     justMoved 期间 background 边框色 = lighter(channelColor, 1.4)
//     （"刚移动高亮"），随后回落到 channelColor；边框色经 BasicColorBehavior
//     动画门控。
//   - value 无限幅（限幅在消费方 ChannelSlider 的 InteractingArea.setValue）。
// 与 v3 的刻意差异：无（仅依赖替换 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

/*!
    \qmltype ChannelBar
    \inqmlmodule Qool.Color
    \brief 通道填充条（v3 逐字迁移）：channelColor 的纵向填充 + 刚移动边框高亮。

    \c value（0..1）决定填充高度（从底部向上）；\c channelColor 决定填充
    与边框色。竖直拖动由消费方（ChannelSlider 的 InteractingArea）映射后写
    本件 \c value。

    \section2 易误解点
    \list
    \li 填充方向是"从底部向上"，与 ColorSlider 的水平方向不同——拖动映射
        （1 - mouseY/height）与填充方向必须配套，改任一侧都会错位。
    \li "刚移动高亮"（movementTimer）由 \b 高度变化触发：只要 value 被写入
        （无论谁写的），边框就亮 1 秒——数值输入编辑时同样会亮，这是 v3 行为。
    \li 边框色只在 justMoved 与常态间切换，无 hover 态（v3 原样）。
    \endlist
*/
T.Control {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property color channelColor
    property real radius: 5
    property real value: 1

    contentItem: Item {
        implicitHeight: 100
        implicitWidth: 30
        Rectangle {
            id: fillRect
            radius: Math.max(0, root.radius - root.padding)
            width: parent.width
            height: parent.height * root.value
            y: parent.height - height
            border.width: 0
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.channelColor, 0.9)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.channelColor, 0.1)
                }
            }
            onHeightChanged: movementTimer.when_moved()
        }

        Rectangle {
            id: bgRect
            radius: Math.max(0, root.radius - root.padding)
            anchors.fill: parent
            z: -1
            border.width: 0
            color: Qt.alpha(root.channelColor, 0.1)
        }
    } //contentItem

    padding: 4

    background: Rectangle {
        implicitHeight: 10
        implicitWidth: 10
        radius: root.padding
        color: "transparent"
        border.width: 1
        border.color: movementTimer.justMoved ? Qt.lighter(
                                                    root.channelColor,
                                                    1.4) : root.channelColor
        BasicColorBehavior on border.color {
            enabled: root.animationEnabled
        }
    }

    Timer {
        id: movementTimer
        property bool justMoved: false
        interval: 1000
        onTriggered: justMoved = false
        function when_moved() {
            justMoved = true
            restart()
        }
    }
}
