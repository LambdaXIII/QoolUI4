import QtQuick
import QtQuick.Templates as T
import Qool

T.Control {
    id: root

    property alias text: contentText.text
    property color color: Style.accent
    property alias backgroundSettings: bgBox.settings

    font.pixelSize: Style.controlTextSize

    contentItem: Text {
        id: contentText
        font: root.font
        color: ThemeDB.recommendForeground(root.color, root.Style.dark,
                                           root.Style.light)
        padding: 2
    }

    background: QoolBox {
        id: bgBox
        settings {
            cutSizesLocked: true
            cutSize: 4
            borderColor: contentText.color
            fillColor: root.color
        }
    }

    leftPadding: bgBox.control.leftSpace
    rightPadding: bgBox.control.rightSpace

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
