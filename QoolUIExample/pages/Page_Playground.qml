pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.File

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")
    Column {
        QoolBox {
            width: 400
            height: 300
            settings {
                cutSizeTL: 30
                cutSizeTR: 10
                cutSizeBL: 40
                cutSizeBR: 5
            }
        }

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

            // editable: true
            selectTextByMouse: true
            // flat: true
            // backgroundSettings.cutSizeTL: 30
            onCurrentIndexChanged: {
                box.Style.dumpInfo();
            }
        }
    }
}
