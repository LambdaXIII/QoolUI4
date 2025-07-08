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
        width: 200
        contentItem: ClickableText {
            id: btn
            checkable: true
            text: "Click!"
        }
    }

    ProgressBar {
        id: bar

        anchors.centerIn: parent
        width: 200
        height: 20

        indeterminate: btn.checked
    }
}
