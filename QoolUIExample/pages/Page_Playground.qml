import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root
    Style.theme: "midnight"
    // Style.onCurrentGroupChanged: {
    //     console.log(Style.accent);
    // }
    ControlFrame {
        id: control

        width: 400
        height: 300

        anchors.centerIn: parent
        contentSpacing: 10
        contentItem: Rectangle {
            id: c

            color: Style.accent
            Text {
                text: Style.accent
                anchors.centerIn: parent
            }
        }

        TapHandler {
            onTapped: {
                // console.log(Style.active.accent, Style.inactive.accent, Style.accent);
                console.log(c.Style.theme)
                console.log(c.Style.accent)
                console.log(c.Style.value(Style.Inactive, "accent"))
                console.log(c.Style.value(Style.Disabled, "accent"))
                c.enabled = !c.enabled
            }
        }
    }
}
