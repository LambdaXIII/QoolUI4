import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

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
                c.enabled = !c.enabled

                c.Style.dumpInfo()
            }
        }
    }
}
