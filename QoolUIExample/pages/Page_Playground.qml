import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    // Style.animationEnabled: false
    ControlFrame {
        width: 200
        contentItem: Column {
            ClickableText {
                id: btn
                checkable: true
                text: "Click!"
            }
            ClickableText {
                id: btn2
                checkable: true
                text: "Click!"
            }
        }
    }

    ProgressBar {
        id: bar

        anchors.centerIn: parent
        width: 200
        height: 20

        indeterminate: btn.checked
        horizontalAlignment: btn2.checked ? Qt.AlignRight : Qt.AlignLeft
    }
}
