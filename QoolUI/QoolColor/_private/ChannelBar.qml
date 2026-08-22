// 通道填充条：channelColor 的纵向填充（从底部向上）+ 刚移动边框高亮。
// 竖直拖动由消费方（ChannelSlider 的 InteractingArea）映射后写 value——
// 映射（1 - mouseY/height）与填充方向必须配套。
// "刚移动高亮"由高度变化触发：任何 value 写入（含数值输入编辑）都亮
// 1 秒——刻意行为；边框色无 hover 态。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

T.Control {
    id: root

    // Templates 不传播 contentItem implicit（恒 0）——显式补齐保持独立
    // 使用自洽（contentItem implicit 30x100）；ChannelSlider 以显式尺寸
    // 消费，无影响。
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
