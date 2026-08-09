pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")
    ListModel {
        id: listModel2
        ListElement {
            display: qsTr("AA")
            value: Qore.Covered
        }
        ListElement {
            display: qsTr("BB")
            value: Qore.Above
        }
        ListElement {
            display: qsTr("CC")
            value: Qore.Below
        }
    }

    ComboBox {
        model: listModel2
        // flat:true
        editable: true
        textRole: "display"

        validator: IntValidator {
            bottom: 0
        }

        // onDisplayTextChanged: console.log(displayText, currentText)
        // onCurrentTextChanged: console.log(displayText, currentText)
        onEditTextChanged: console.log(editText)
        onAccepted: console.log("!!")
    }
}
