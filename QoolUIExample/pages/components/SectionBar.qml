import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool

Item {
    id: root

    property color color: Style.mid

    Layout.fillWidth: true
    implicitHeight: 60

    Rectangle {
        id: bar
        color: root.color
        radius: Math.floor(height / 2)
        height: 8
        width: Math.min(root.width / 2, 600)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
    }
}
