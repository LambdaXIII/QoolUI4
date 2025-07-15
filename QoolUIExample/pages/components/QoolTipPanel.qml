import QtQuick
import QtQuick.Controls
import Qool
import Qool.Chat

Floater {
    id: root
    property string text
    property color color: Style.highlight

    content: Control {
        contentItem: Text {
            id: mainText
            text: root.text
            color: ThemeDB.recommendForeground(root.color,
                                               root.Style.buttonText,
                                               root.Style.highlightedText)
            font.pixelSize: root.Style.importantTextSize
        }

        background: QoolBox {
            settings {
                cutSizes: "50 0 50 0"
                borderWidth: 20
                borderColor: root.Style.button
                fillColor: root.color
            }
            round: true
        }

        padding: 25

        implicitWidth: Math.max(
                           200,
                           leftPadding + implicitContentWidth + rightPadding)
        implicitHeight: Math.max(
                            200,
                            topPadding + implicitContentHeight + bottomPadding)
    }

    opacity: 0

    Beeper {
        id: beeper
        chatRoom: GlobalChatRoom
        channel: "qooltip"
        onMessageRecieved: msg => {
                               if (msg.content)
                               showText(msg.content)
                               else
                               hide()
                           }
    }

    x: parent.width - width
    y: parent.height - height

    function showText(t: string) {
        root.text = t
        root.opacity = 1
    }

    function hide() {
        root.opacity = 0
    }
}
