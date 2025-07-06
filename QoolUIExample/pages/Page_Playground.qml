import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

Item {
    id: root

    ItemTracker {
        id: tracker
        target: root
    }

    ControlFrame {
        id: control

        width: 400
        height: 300

        anchors.centerIn: parent
        contentSpacing: 10
        contentItem: Rectangle {
            color: tracker.windowActived ? "red" : "yellow"
        }

        TapHandler {
            onTapped: {
                console.log(tracker.window, tracker.item)
            }
        }
    }
}
