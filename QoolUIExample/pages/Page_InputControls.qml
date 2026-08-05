// 标准输入控件演示页：展示 Qool.Controls 重写的 ComboBox（标题、
// 背景定制、QoolTip 说明）以及 SectionBar、Dial 等控件。
//
// 刻意设计（修复说明）：组合框的弹出方向取自
// listModel2.get(currentIndex).value——Qool.Controls.ComboBox（继承
// T.ComboBox）不提供 currentValue，valueRole 亦不存在，方向枚举值
// （Qore.Covered/Above/Below）必须经 ListModel 行对象取回。
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
            // Qool.Controls.ComboBox（继承 T.ComboBox）无 currentValue：
            // 方向值经 ListModel.get(currentIndex) 取（valueRole 亦不存在）
            popupDirection: listModel2.get(box3.currentIndex).value
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
            popupDirection: listModel2.get(box3.currentIndex).value
            QoolTip {
                //% "QoolUI版的ComboBox可以设置标题
                text: qsTrId("qooltip-combobox-titled")
            }
        }

        ComboBox {
            id: box3
            model: listModel2
            textRole: "display"
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
