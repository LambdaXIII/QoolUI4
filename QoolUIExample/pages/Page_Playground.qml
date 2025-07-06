import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root

    Style.active.accent: "red"
    Style.inactive.accent: "blue"

    ControlFrame {
        id: control

        width: 400
        height: 300

        anchors.centerIn: parent
        contentSpacing: 10
        contentItem: Rectangle {
            color: Style.accent
        }

        TapHandler {
            onTapped: {
                console.log(Style.active.accent, Style.inactive.accent,
                            Style.accent)
            }
        }
    }
}
