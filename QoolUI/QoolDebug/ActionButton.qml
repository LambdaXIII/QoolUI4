import QtQuick
import QtQuick.Controls.Basic
import "_private"

AbstractButton {
    id: root

    padding: 4
    contentItem: Item {
        implicitHeight: 24
        implicitWidth: 100
        Text {
            text: root.text
            color: root.down ? palette.button : palette.buttonText
            anchors.centerIn: parent
            font.pixelSize: 12
        }

        Rectangle {
            visible: root.checkable
            color: root.checked ? palette.highlight : palette.midlight
            width: 8
            height: 8
            radius: 4
            border.width: 0
            x: 4
            y: 4
        }
    }

    background: BGBox {
        border.color: root.hovered ? palette.highlight : palette.shadow
        color: root.down ? palette.highlight : palette.button
    }
}
