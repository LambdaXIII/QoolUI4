import QtQuick
import QtQuick.Controls
import Qool
import Qool.Chat

Floater {
    id: root
    property string text
    property color color: Style.highlight
    property color textColor: ThemeDB.recommendForeground(
                                  root.color, root.Style.buttonText,
                                  root.Style.highlightedText)

    property real maximumWidth: 400
    property real maximumHeight: 400

    property bool backupPosition: false

    width: Math.min(maximumWidth, implicitWidth)
    height: Math.min(maximumHeight, implicitHeight)

    content: Control {
        contentItem: Text {
            id: mainText
            text: root.text
            color: root.textColor
            font.pixelSize: root.Style.controlTextSize
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            textFormat: Text.MarkdownText
            BasicTextBehavior on text {}
            BasicColorBehavior on color {}
        }

        background: QoolBox {
            settings {
                cutSizes: "5 0 20 0"
                borderWidth: 1
                borderColor: root.textColor
                fillColor: Qt.alpha(root.color, 0.75)
            }
            BasicColorBehavior on settings.fillColor {}
            BasicColorBehavior on settings.borderColor {}
            curved: true
        }

        leftPadding: 10
        rightPadding: 5
        topPadding: 5
        bottomPadding: 25

        implicitWidth: Math.max(
                           20,
                           leftPadding + implicitContentWidth + rightPadding)
        implicitHeight: Math.max(
                            25,
                            topPadding + implicitContentHeight + bottomPadding)

        hoverEnabled: true
        onHoveredChanged: if (hovered)
                              root.backupPosition = !root.backupPosition
    }

    opacity: 0

    Beeper {
        id: beeper
        chatRoom: GlobalChatRoom
        channel: "qooltip"
        onMessageRecieved: msg => {
                               if (msg.content)
                               showText(msg.content)

                               if (msg.contains("color"))
                               root.color = msg.attachment("color")
                           }
    }

    x: parent.width - width
    y: root.backupPosition ? 0 : (parent.height - height)

    function showText(t: string) {
        root.text = t
        root.opacity = 1
    }

    function hide() {
        root.text = ""
        root.opacity = 0
    }

    BasicNumberBehavior on opacity {
        easing.type: Easing.InOutQuad
    }

    BasicNumberBehavior on height {
        easing.type: Easing.InOutQuad
    }
    BasicNumberBehavior on width {
        easing.type: Easing.InOutQuad
    }
    BasicNumberBehavior on y {
        duration: Style.movementDuration
        easing.type: Easing.InOutQuad
    }
}
