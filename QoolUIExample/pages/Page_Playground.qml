pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.File
import Qool.Models

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    ComboBox {
        id: box
        model: ListModel {
            ListElement {
                display: "first"
                value: 1
            }
            ListElement {
                display: "second"
                value: 2
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
            ListElement {
                display: "third"
                value: 3
            }
        }
        textRole: "display"
        valueRole: "value"
        onCurrentIndexChanged: console.log(currentValue)
    }
}
