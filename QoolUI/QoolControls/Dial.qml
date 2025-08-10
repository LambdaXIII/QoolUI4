import QtQuick
import QtQuick.Templates as T
import Qool
import "_private"

T.Dial {
    id: root

    background: Rectangle {
        id: bgbox
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        implicitWidth: 50
        implicitHeight: 50

        width: Math.max(35, Math.min(root.width, root.height))
        height: width
        radius: width / 2
        border.color: root.Style.alternateBase
        color: root.Style.buttonText

        DialBackground {
            anchors.fill: parent
        }
    }

    handle: Rectangle {
        id: handleItem
        x: root.background.x + (root.background.width - width) / 2
        y: root.background.y + (root.background.height - height) / 2
        width: 4
        height: Math.max(root.background.width * 0.3, 4)
        radius: width / 2
        color: Style.alternateBase
        transform: [
            Translate {
                y: Math.min(root.background.width, root.background.height) * 0.4 * -1 + handleItem.height / 2
            },
            Rotation {
                angle: root.angle
                origin.x: handleItem.width / 2
                origin.y: handleItem.height / 2
            }
        ]
    }

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    Binding {
        when: root.pressed
        bgbox.color: root.Style.highlight
        bgbox.border.color: root.Style.highlightedText
        handleItem.color: root.Style.highlightedText
    }
}
