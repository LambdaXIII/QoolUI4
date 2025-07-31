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

    ListModel {
        id: listModel1
        ListElement {
            display: qsTr("小明")
            value: 1
        }
        ListElement {
            display: qsTr("小李")
            value: 2
        }
        ListElement {
            display: qsTr("大美")
            value: 3
        }
        ListElement {
            display: qsTr("笨笨")
            value: 4
        }
    }

    readonly property list<string> listModel2: [qsTr("第一个选项"), qsTr(
            "第二个选项"), qsTr("第三个选项"), qsTr("第四个选项")]

    Column {
        id: cc

        spacing: 25

        ComboBox {
            id: box1
            model: listModel2
            enabled: box2.currentValue % 2 != 0
            QoolTip {
                //% "介绍QoolUI版的ComboBox
                text: qsTrId("qooltip-combobox")
            }
        }

        ComboBox {
            id: box2
            model: listModel1
            textRole: "display"
            valueRole: "value"
            title: qsTr("你最喜欢的人是？")
            currentIndex: 0
            font.pixelSize: 32
            QoolTip {
                //% "QoolUI版的ComboBox可以设置标题
                text: qsTrId("qooltip-combobox-title")
            }
        }

        ComboBox {
            id: box3
            model: listModel1
            textRole: "display"
            valueRole: "value"
            title: qsTr("你最喜欢的人是？")
            currentIndex: box2.currentIndex
            font.pixelSize: 24
            enabled: box1.enabled
            backgroundSettings: QoolBoxSettings {
                cutSizeTL: root.Style.controlCutSize
                borderWidth: root.Style.controlBorderWidth
                borderColor: root.Style.controlBorderColor
                fillColor: root.Style.controlBackgroundColor
            }
            horizontalAlignment: Text.AlignRight
            QoolTip {
                //% "通过设置背景属性甚至可以恢复QoolControl原本的样式
                text: qsTrId("qooltip-combobox-reshape")
            }
        }
    } //cc
}
