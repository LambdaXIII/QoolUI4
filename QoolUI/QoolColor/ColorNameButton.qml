import QtQuick
import QtQuick.Controls.Basic as B

import Qool
import Qool.Color

import "_private"

B.AbstractButton {
    id: root

    property color color: "white"

    text: ColorHQ.colorName(root.color)
    font: PixelFont.normal

    background: Rectangle {
        implicitWidth: 20
        implicitHeight: 20

        radius: 4

        readonly property color themeColor: {
            let c = root.color;
            return ThemeHQ.recommendForeground(c, ColorHQ.keepItBright(c), ColorHQ.keepItDark(c));
        }

        border.width: root.down ? 4 : 2
        border.color: Qt.alpha(themeColor, 0.8)
        color: root.down ? Qt.alpha(themeColor, 0.2) : Qt.alpha(themeColor, 0)
        opacity: root.hovered ? 1 : 0
        visible: opacity > 0
        BasicNumberBehavior on opacity {
            enabled: root.Style.animationEnabled
        }
    }

    padding: 4
    contentItem: ColorNameButtonSurface {
        id: surface
        colorName: root.text
        color: root.color
        highlighted: root.checkable && root.checked
        font: root.font

        Binding {
            target: surface
            property: "textColor"
            value: Style.negative
            when: !root.enabled
        }
        Binding {
            target: surface
            property: "borderColor"
            value: Style.negative
            when: !root.enabled
        }
    }
}
