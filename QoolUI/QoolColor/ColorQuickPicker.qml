pragma ComponentBehavior: Bound

import QtQuick
import Qool
import "_private"

/*!
    \qmltype ColorQuickPicker
    \inqmlmodule Qool.Color
    \brief HSV 渐变快速取色器（v3 ColorQuickPicker 迁移）。

    悬停时渐显全饱和 HSV 渐变面（水平色相 × 竖直明度），在面上
    \b 按住拖动或长按即可取色；双击重置回 \l defaultColor。默认
    （未悬停）显示 \l currentColor 实色与前景对比边框。

    \section1 交互

    \list
    \li 悬停：HSV 渐变面渐显，边框变为 \l currentColor。
    \li 取色：按住拖动（或长按）——\c currentColor =
        \c Qt.hsla(hue, 1, lightness, 1)：\c hue 随鼠标 X 从 0（左）到
        1（右），\c lightness 随鼠标 Y 从 1（上）到 0（下）。
        \b 单击（不拖动、不按住）不取色——v3 行为照迁。
    \li 双击：重置 \c currentColor = \c defaultColor。
    \li 键盘：悬停进入时自动获得焦点，此后 Alt 键行为生效（见下）。
    \endlist

    \section2 Alt 键行为（易误解，特别说明）

    \b 按住 Alt 键时：
    \list
    \li 明度渐变（valueBox）隐藏，只显示纯色相渐变；
    \li 取色时 \c lightness 固定 0.5（中等明度），不再随鼠标 Y 变化——
        此时取到的是"纯色相"色。
    \endlist
    Alt 是临时切换：\b 取色过程中需保持按住 Alt，松手即恢复明度模式。
    键事件经 \c Keys 附加属性处理，要求本组件拥有活动焦点（悬停进入时
    自动 \c forceActiveFocus）；若焦点被宿主抢占，Alt 切换不生效。
    \note 取色始终在全饱和（s=1）面上进行，本组件取不到低饱和/灰色。

    \section2 默认值

    \c currentColor 默认等于 \c defaultColor（\c "white"）——默认状态
    自洽（v3 中 \c currentColor 无默认值，独立使用时为黑；v4 改为跟随
    \c defaultColor，宿主绑定用法不变）。双击重置的目标是 \c defaultColor。

    \section1 属性

    \qmlproperty color ColorQuickPicker::currentColor
    当前取色结果。拖动/长按取色时写入 \c Qt.hsla(hue, 1, lightness, 1)；
    双击或 \l reset() 写回 \l defaultColor。宿主可通过双向绑定同步到
    \l ColorAssistant。

    \qmlproperty color ColorQuickPicker::defaultColor
    双击重置的目标色，默认 \c "white"。

    \qmlproperty bool ColorQuickPicker::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}
    （v4 惯例）。为 false 时渐变显隐与边框变色即时完成。

    \section1 方法

    \qmlmethod void ColorQuickPicker::reset()
    将 \c currentColor 重置为 \l defaultColor（与双击等价）。
*/
Item {
    id: root

    // 动画总开关：v4 惯例，取自父级或附加 Style。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled
    property color currentColor: defaultColor
    property color defaultColor: "white"

    implicitHeight: 50
    implicitWidth: 200

    QtObject {
        id: pControl
        property real radius: 5
        property color foregroundColor: ThemeHQ.recommendForeground(
                                            root.currentColor)
        property bool altPressed: false
    }

    Keys.onPressed: ev => {
                        if (ev.key === Qt.Key_Alt)
                        pControl.altPressed = true
                    }

    Keys.onReleased: ev => {
                         if (ev.key === Qt.Key_Alt)
                         pControl.altPressed = false
                     }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: pControl.radius
        color: root.currentColor
        border.width: 0
    }

    Rectangle {
        id: hueBox
        anchors.fill: parent
        radius: pControl.radius
        border.width: 0
        opacity: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
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
        Rectangle {
            id: valueBox
            anchors.fill: parent
            radius: pControl.radius
            border.width: 0
            opacity: pControl.altPressed ? 0 : 1
            BasicNumberBehavior on opacity {
                enabled: root.animationEnabled
            }
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0
                    color: "white"
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: "black"
                }
            }
        } //valueBox
    } //hueBox

    Rectangle {
        id: borderBox
        anchors.fill: parent
        radius: pControl.radius
        border.width: 1
        color: "transparent"
        border.color: pControl.foregroundColor
    } //borderBox

    InteractingArea {
        id: mouseArea
        cursorShape: Qt.CrossCursor
        hoverEnabled: true
        function set_color() {
            const hue = mouseX / parent.width
            let lightness = 0.5
            if (!pControl.altPressed)
                lightness = 1 - mouseY / parent.height
            if (userInteracting) {
                root.currentColor = Qt.hsla(hue, 1, lightness, 1)
            }
        }
        onPressAndHold: set_color()
        onPositionChanged: set_color()
        onDoubleClicked: root.reset()
        onEntered: root.forceActiveFocus()
    } //mouseArea

    states: [
        State {
            when: mouseArea.containsMouse || mouseArea.userInteracting
            PropertyChanges {
                hueBox.opacity: 1
                borderBox.border.color: root.currentColor
            }
        }
    ]

    transitions: [
        Transition {
            enabled: root.animationEnabled && (!mouseArea.userInteracting)
            NumberAnimation {
                property: "opacity"
                duration: Style.movementDuration
                easing.type: Easing.InOutQuad
            }
            ColorAnimation {
                property: "color"
                duration: Style.transitionDuration
                easing.type: Easing.InOutQuart
            }
        }
    ]

    function reset() {
        root.currentColor = root.defaultColor
    }
}
