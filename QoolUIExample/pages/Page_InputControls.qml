import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components

import "components"

BasicPage {
    id: root

    title: qsTr("标准输入控件")
    note: qsTr("Qool.Controls 重写了多种标准输入控件")

    implicitHeight: cc.implicitHeight

    readonly property list<string> listModel1: [qsTr("小明"), qsTr("小李"), qsTr("大美"), qsTr(
            "笨笨")]

    ListModel {
        id: listModel2
        ListElement {
            display: qsTr("正常")
            value: Qore.Covered
        }
        ListElement {
            display: qsTr("向上")
            value: Qore.Above
        }
        ListElement {
            display: qsTr("向下")
            value: Qore.Below
        }
    }

    Column {
        id: cc

        spacing: 25

        ComboBox {
            id: box1
            model: listModel1
            enabled: box2.currentIndex != currentIndex
            currentIndex: 0
            popupDirection: box3.currentValue
            QoolTip {
                //% "介绍QoolUI版的ComboBox
                text: qsTrId("qooltip-combobox-normal")
            }
        }

        ComboBox {
            id: box2
            model: listModel1
            title: qsTr("你最喜欢的人是？")
            currentIndex: 1
            font.pixelSize: 32
            popupDirection: box3.currentValue
            QoolTip {
                //% "QoolUI版的ComboBox可以设置标题
                text: qsTrId("qooltip-combobox-titled")
            }
        }

        ComboBox {
            id: box3
            model: listModel2
            textRole: "display"
            valueRole: "value"
            title: qsTr("设置菜单弹出方向")
            currentIndex: 0
            font.pixelSize: 24
            backgroundSettings: QoolBoxSettings {
                cutSizeTL: root.Style.controlCutSize
                borderWidth: root.Style.controlBorderWidth
                borderColor: root.Style.controlBorderColor
                fillColor: root.Style.controlBackgroundColor
            }
            editable: true
            horizontalAlignment: Text.AlignRight
            QoolTip {
                //% "通过设置背景属性甚至可以恢复QoolControl原本的样式
                text: qsTrId("qooltip-combobox-customed")
            }
        }

        SectionBar {
            width: parent.width
        }

        Dial {}
    } //cc
}
