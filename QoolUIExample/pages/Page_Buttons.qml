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
                text: "QoolUI提供一个普通的按钮，在引入 Qool.Controls 时，它将自动覆盖掉 QtQuick.Controls.Button。"
                color: Style.yellow
            }
        }

        Button {
            text: qsTr("QoolUI的按钮")
            flat: true
            QoolTip {
                text: "这个种按钮完全兼容标准按钮中的 highlighted 和 flat 属性。"
                color: Style.blue
            }
        }
    }
}
