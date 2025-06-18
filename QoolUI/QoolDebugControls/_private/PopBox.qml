import QtQuick
import QtQuick.Controls.Basic

SlimPopup {
    id: root

    property real size: 12
    property real borderWidth: 2
    property color color: palette.highlight
    property bool solid: false
    readonly property real displaySize: Math.max(2, size + borderWidth * 2)

    width: displaySize
    height: displaySize

    Rectangle {
        border.width: root.borderWidth
        border.color: root.color
        color: root.solid ? root.color : "transparent"
        width: root.size
        height: root.size
        anchors.centerIn: parent
    }
}
