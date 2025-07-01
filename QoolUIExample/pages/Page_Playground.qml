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
        enabled: false
        backgroundSettings.cutSize: 200
    }
}
