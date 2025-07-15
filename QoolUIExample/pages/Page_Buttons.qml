import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components
import "components"

BasicPage {

    id: root

    title: qsTr("酷酷的按钮")
    note: qsTr("QoolUI提供了风格化的按钮")

    Column {

        Button {
            text: qsTr("QoolUI的按钮")
            QoolTip {
                text: "exe"
            }
        }

        GroupBox {
            title: qsTr("按钮组")
            Column {
                Button {
                    text: "a"
                }
                Button {
                    text: "b"
                }
                Button {
                    text: "c"
                }
                Button {
                    text: "d"
                }
            }
        }
    }
}
