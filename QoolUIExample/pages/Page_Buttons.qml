import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Controls
import Qool.Controls.Components
import "components"

BasicPage {

    id: root

    title: qsTr("酷酷的按钮")
    note: qsTr("QoolUI提供了风格化的按钮")

    implicitHeight: cc.implicitHeight

    ColumnLayout {
        id: cc
        width: parent.width

        Button {
            text: qsTr("QoolUI的按钮")
            QoolTip {
                //% "普通按钮的介绍"
                text: qsTrId("qooltip-basic-button-1")
                color: Style.yellow
            }
        }

        Button {
            text: qsTr("标记为 flat 的按钮")
            flat: true
            QoolTip {
                //% "介绍按钮对于 flat 和 highlighted 的支持"
                text: qsTrId("qooltip-basic-button-flat-and-highlighted")
                color: Style.blue
            }
        }

        SectionBar {}
    } //cc
}
