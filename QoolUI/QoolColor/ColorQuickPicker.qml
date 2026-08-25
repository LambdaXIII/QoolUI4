pragma ComponentBehavior: Bound

import QtQuick
import Qool
import "_private"

Item {
    id: root

    // 动画总开关：v4 惯例，取自父级或附加 Style。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property color color: "white"

    implicitHeight: 50
    implicitWidth: 200

    QtObject {
        id: pControl
        property real radius: 5
        property color foregroundColor: ThemeHQ.recommendForeground(root.color)
        property bool altPressed: false
    }

    // Alt 键临时切换（需保持活动焦点；悬停进入时已 forceActiveFocus）：
    // 按住时隐藏明度渐变、取色 lightness 固定 0.5（纯色相模式），
    // 松手即恢复明度模式。
    Keys.onPressed: ev => {
        if (ev.key === Qt.Key_Alt)
            pControl.altPressed = true;
    }

    Keys.onReleased: ev => {
        if (ev.key === Qt.Key_Alt)
            pControl.altPressed = false;
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: pControl.radius
        color: root.color
        border.width: 0
    }

    RectShape {
        id: hueBox
        anchors.fill: parent
        radius: pControl.radius
        borderWidth: 0
        opacity: 0
        fillGradient: RainbowGradient {
            width: hueBox.width
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
            // 取色恒在全饱和（s=1）面进行——取不到低饱和/灰色；
            // 单击（不拖动、不按住）不取色。
            const hue = mouseX / parent.width;
            let lightness = 0.5;
            if (!pControl.altPressed)
                lightness = 1 - mouseY / parent.height;
            if (userInteracting) {
                root.color = Qt.hsla(hue, 1, lightness, 1);
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
                borderBox.border.color: root.color
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
}
