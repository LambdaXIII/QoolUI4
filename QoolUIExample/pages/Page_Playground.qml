import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root

    Style.theme: "midnight"
    Style.onCurrentGroupChanged: {
        console.log(Style.accent);
    }

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
                // console.log(Style.active.accent, Style.inactive.accent, Style.accent);
                console.log(root.Style.theme);
                console.log(root.Style.accent);
                console.log(root.Style.value(Style.Inactive, "accent"));
                console.log(root.Style.value(Style.Disabled, "accent"));
            }
        }
    }
}
