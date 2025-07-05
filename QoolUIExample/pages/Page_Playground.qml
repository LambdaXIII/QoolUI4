import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root

    // Style.active.accent: "red"
    // Style.inactive.accent: "blue"
    Style.theme: "midnight"
    Style.active.highlight: "blue"
    Style.inactive.highlight: "green"

    ControlFrame {
        id: control

        width: 400
        height: 300

        anchors.centerIn: parent
        contentSpacing: 10
        contentItem: Rectangle {
            color: Style.highlight
        }

        Style.onValueChanged: console.log(Style.active.highlight,
                                          Style.inactive.highlight,
                                          Style.highlight)

        TapHandler {
            onTapped: {
                console.log(Style.active.highlight, Style.inactive.highlight,
                            Style.highlight)
            }
        }
    }
}
