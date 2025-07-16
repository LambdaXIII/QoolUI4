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
                //% "Tip for the plain simple button"
                text: qsTrId("qooltip-basic-button-1")
                color: Style.yellow
            }
        }

        Button {
            text: qsTr("QoolUI的按钮")
            flat: true
            QoolTip {
                //% "Introduce that the button has flat and highlighted properties."
                text: qsTrId("qooltip-basic-button-flat-and-highlighted")
                color: Style.blue
            }
        }
    }
}
