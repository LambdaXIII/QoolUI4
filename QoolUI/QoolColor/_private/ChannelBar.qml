// 通道填充条：channelColor 的纵向填充 + 刚移动边框高亮（竖直拖动由
// 消费方 ChannelSlider 的 InteractingArea 映射后写 value）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

// 通道填充条：channelColor 的纵向填充 + 刚移动边框高亮。
//
// `value`（0..1）决定填充高度（从底部向上）；`channelColor` 决定填充
// 与边框色。竖直拖动由消费方（ChannelSlider 的 InteractingArea）映射后写
// 本件 `value`。
//
// 易误解点
// - 填充方向是"从底部向上"，与 ColorSlider 的水平方向不同——拖动映射
//   （1 - mouseY/height）与填充方向必须配套，改任一侧都会错位。
// - "刚移动高亮"（movementTimer）由高度变化触发：只要 value 被写入
//   （无论谁写的），边框就亮 1 秒——数值输入编辑时同样会亮，这是刻意行为。
// - 边框色只在 justMoved 与常态间切换，无 hover 态。
T.Control {
    id: root

    // 根为 T.Control 时 Templates 不传播 contentItem implicit——implicit
    // 恒 0；此处显式补齐保持独立使用自洽（contentItem implicit 30x100）。
    // ChannelSlider 以显式尺寸消费（preferredHeight/fillWidth），无影响。
    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

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
