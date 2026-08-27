import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Basic
import Qool

Basic.MenuSeparator {
    id: root

    property string text
    property color color: Style.accent
    property color textColor: ThemeHQ.recommendForeground(color)
    property real borderWidth: 1
    property alias horizontalAlignment: main.horizontalAlignment
    property alias verticalAlignment: main.verticalAlignment
    property alias elide: main.elide
    property alias wrapMode: main.wrapMode
    property alias textFormat: main.textFormat

    font.pixelSize: Style.decorativeTextSize

    contentItem: Text {
        id: main
        text: root.text
        color: root.textColor
        font: root.font
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        padding: root.Style.menuCutSize / 2 + root.borderWidth
    }

    background: Rectangle {
        border.width: root.borderWidth
        border.color: root.textColor
        color: root.color
        radius: root.Style.menuCutSize
        BasicColorBehavior on color {
            enabled: root.Style.animationEnabled
        }
    }//background
}
