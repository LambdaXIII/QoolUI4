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

    Column {
        id: cc
        // width: parent.width
        spacing: 15

        Button {
            text: qsTr("默认按钮")
            QoolTip {
                //% "普通按钮的介绍"
                text: qsTrId("qooltip-basicbutton")
                color: Style.yellow
            }
        }

        Button {
            text: qsTr("标记为 flat 的按钮")
            flat: true
            QoolTip {
                //% "介绍按钮对于 flat 和 highlighted 的支持"
                text: qsTrId("qooltip-basicbutton-extra-properties")
                color: Style.blue
            }
        }

        Button {
            text: checked ? qsTr("已经 Check 的按钮") : qsTr("可以 Check 的按钮")
            checkable: true
            QoolTip {
                //% "介绍按钮对于 flat 和 highlighted 的支持"
                text: qsTrId("qooltip-basicbutton-extra-properties")
                color: Style.blue
            }
        }

        SectionBar {
            width: root.width
        }

        ColumnLayout {
            implicitWidth: 350
            QoolButton {
                title: qsTr("这是一个酷酷的按钮")
                text: qsTr("酷酷的按钮")
                QoolTip {
                    //% "介绍QoolButton"
                    text: qsTrId("qooltip-qoolbutton")
                    color: Style.cyan
                }
                Layout.fillWidth: true
            }

            QoolButton {
                title: qsTr("酷酷的按钮也可以有 flat 模式")
                text: qsTr("平平无奇的酷酷的按钮")
                flat: true
                QoolTip {
                    //% "QoolButton也可以flat"
                    text: qsTrId("qooltip-qoolbutton-extra-properties")
                    color: Style.green
                }
                Layout.fillWidth: true
            }

            QoolButton {
                id: animeButton
                title: qsTr("可以开关的按钮")
                text: checked ? qsTr("动画已启用") : qsTr("动画已禁用")
                checked: true
                checkable: true
                QoolTip {
                    //% "介绍QoolButton的checkable属性"
                    text: qsTrId("qooltip-qoolbutton-checkable")
                    color: Style.green
                }
                Layout.fillWidth: true
            }

            QoolButton {
                id: disabledButton
                title: qsTr("被禁用的按钮")
                text: qsTr("奏凯！别摸我！")
                enabled: false
                Style.animationEnabled: animeButton.checked
                QoolTip {
                    //% "介绍如何控制组件的动画"
                    text: qsTrId("qooltip-qoolbutton-animation")
                    color: Style.green
                }
                Layout.fillWidth: true
            }
        }

        ExampleBasicButton {
            implicitWidth: 400
            implicitHeight: 250
            QoolTip {
                //% "介绍 BasicButton 货 papa words"
                text: qsTrId("qooltip-basicbutton-example")
            }
        }
    } //cc
}
