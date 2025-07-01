import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root

    ControlFrame {
        id: control

        width: 400
        height: 300

        anchors.centerIn: parent
        backgroundSettings.cutSize: 200
        contentSpacing: 10
        contentItem: BasicButton {
            text: "HELLO!"
            flat: !hovered
            showTitle: true
        }
    }
}
