import QtQuick
import QtQuick.Templates as T
import Qool

/*!
    \qmltype BasicLabel
    \inqmlmodule Qool
    \brief 带 QoolBox 背景的文本标签控件。

    文本颜色自动按 \c color 与当前 \l Style 明暗背景计算对比色；
    背景为 \l QoolBox，四个角统一圆角（\c cutSizes: 4）。
    可通过 \c backgroundSettings 覆写背景外观。
*/
T.Control {
    id: root

    property alias text: contentText.text
    property color color: Style.accent
    property alias backgroundSettings: bgBox.settings

    font.pixelSize: Style.controlTextSize

    contentItem: Text {
        id: contentText
        font: root.font
        color: ThemeHQ.recommendForeground(root.color, root.Style.dark,
                                           root.Style.light)
        padding: 2
    }

    background: QoolBox {
        id: bgBox
        settings {
            cutSizes: 4
            borderColor: contentText.color
            fillColor: root.color
        }
    }

    leftPadding: bgBox.control.leftSpace
    rightPadding: bgBox.control.rightSpace

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
