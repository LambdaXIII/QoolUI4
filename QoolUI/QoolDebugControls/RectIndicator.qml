import QtQuick
import "_private"

Item {
    id: root

    property string name
    property bool showPosition: true
    property bool showSize: true
    property color color: palette.highlight
    property bool solid: false
    property real borderWidth: 1

    anchors.fill: parent

    SlimPopup {
        id: pop
        width: parent.width
        height: parent.height
        Rectangle {
            anchors.fill: parent
            color: root.solid ? root.color : "transparent"
            border.width: root.borderWidth
            border.color: root.color
            Text {
                text: root.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 24
                color: root.color
                anchors.centerIn: parent
            }

            Row {
                id: positions
                visible: root.showPosition
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: root.borderWidth
                PropertyTipText {
                    title: "x"
                    titleColor: root.color
                    displayValue: root.x
                }
                PropertyTipText {
                    title: "y"
                    titleColor: root.color
                    displayValue: root.y
                }
            }

            PropertyTipText {
                title: "width"
                titleColor: root.color
                displayValue: root.width
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.borderWidth
                visible: root.showSize
            }
            PropertyTipText {
                title: "height"
                titleColor: root.color
                displayValue: root.height
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: root.borderWidth
                visible: root.showSize
            }

            Row {
                id: brPositions
                visible: root.showPosition
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: root.borderWidth
                PropertyTipText {
                    title: "x"
                    titleColor: root.color
                    displayValue: root.x + root.width
                }
                PropertyTipText {
                    title: "y"
                    titleColor: root.color
                    displayValue: root.y + root.height
                }
            }
        } //box
    } //pop
}
