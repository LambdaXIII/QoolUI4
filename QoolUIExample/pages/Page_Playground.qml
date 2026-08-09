// Playground：测试场——Qool.Controls 控件的展示性实现与调试用例（仓库
// 开发模式：可随意更改，不保留旧内容）。
//
// 当前内容：
//   1. TextField 系列（名字输入/Validator 支持/自定义输出格式——调试用例）
//   2. SpinBox（可编辑数值步进——编辑会话由 TextField 双层承担）
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls
import Qool.Controls.Components
import QtQuick.Layouts
import "components"

BasicPage {
    id: root

    title: qsTr("数值步进器")
    note: qsTr("Qool.Controls 重写的 SpinBox（整数/小数步进）")

    implicitHeight: cc.implicitHeight

    Column {
        id: cc

        spacing: 25

        QoolControl {
            title: qsTr("试试输入你的名字")
            width: 200
            contentItem: ColumnLayout {
                TextField {
                    id: nameInputField
                    text: qsTr("我的名字是小花")
                    font.pixelSize: Style.titleTextSize
                    Layout.fillWidth: true
                    onAccepted: {
                        if (!text)
                            greeting_text.text = "";
                        else
                            greeting_text.text = qsTr("你好，%1！").arg(text);
                    }
                    displayTextFromText: function (t) {
                        if (!t)
                            return qsTr("(在此输入你的名字)");
                        return t;
                    }
                }
                BasicControlText {
                    id: greeting_text
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    BasicTextBehavior on text {}
                    visible: text
                    color: Style.accent
                }
            }

            QoolTip {
                text: qsTr("QoolUI提供了一个**高定**版本的TextField。基本用法和标准的类似，但是实现了更多可能性。")
            }
        }

        // —— TextField + validator 用例（DoubleValidator 0~100 两位小数）——
        // 测试点：
        //   1. 点击进入编辑 → 编辑栏显示当前 text（= "12.5"）
        //   2. 输入合法值（如 33.33）Enter/失焦 → accepted + text 更新
        //   3. 输入非法值（如 200 超界、abc 非数字）Enter/失焦 → rejected
        //      + text 不变（judge 判定——编辑层不挂 validator）

        QoolControl {
            id: validatorExample
            title: qsTr("Validator支持")
            width: 200
            contentItem: ColumnLayout {
                spacing: 8
                TextField {
                    Layout.fillWidth: true
                    text: "12.5"
                    validator: DoubleValidator {
                        bottom: 0
                        top: 100
                        decimals: 2
                    }
                    onAccepted: validatorExample.whenAccepted()
                    onRejected: validatorExample.whenRejected()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("接受0~100之间的实数")
                    ToolTip.delay: 500
                }

                TextField {
                    Layout.fillWidth: true
                    text: "12"
                    validator: IntValidator {
                        bottom: -100
                        top: 100
                    }
                    onAccepted: validatorExample.whenAccepted()
                    onRejected: validatorExample.whenRejected()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("接受+-100之间的整数")
                    ToolTip.delay: 500
                }

                TextField {
                    Layout.fillWidth: true
                    text: "abc@company.com"
                    validator: RegularExpressionValidator {
                        regularExpression: /^.+@.+\..+/
                    }

                    onAccepted: validatorExample.whenAccepted()
                    onRejected: validatorExample.whenRejected()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("接受电子邮件地址")
                    ToolTip.delay: 500
                }
            }//contentItem

            function whenAccepted() {
                backgroundSettings.borderColor = Style.positive;
            }

            function whenRejected() {
                backgroundSettings.borderColor = Style.negative;
            }
        }

        QoolControl {
            id: displayOverrideEx
            title: qsTr("自定义输出格式")
            width: 200
            contentItem: ColumnLayout {
                TextField {
                    id: displayOverrideField
                    Layout.fillWidth: true
                    Connections {
                        target: nameInputField
                        function onAccepted() {
                            displayOverrideField.text = nameInputField.text;
                        }
                    }

                    displayTextFromText: function (text) {
                        if (!text)
                            return "Hello, World!";
                        return qsTr("你好，%1！").arg(text);
                    }
                    font.pixelSize: Style.titleTextSize
                }
                TextField {
                    Layout.fillWidth: true
                    text: "188"
                    validator: DoubleValidator {
                        bottom: 100
                        top: 999
                        decimals: 2
                    }
                    displayTextFromText: function (text) {
                        return qsTr("%1体重%2公斤").arg(displayOverrideField.text).arg(text);
                    }
                    textFromEditText: function (text) {
                        let x = parseFloat(text);
                        return x + 10;
                    }
                }
            }//layout
            QoolTip {
                text: qsTr("TextField可以使用*displayTextFromText*方法重新设定输出格式。*textFromEditText*可用于讲输入的内容转换为值。这两个方法是独立的，并不一定互为逆运算。\n本组示例中第一个是一个简单的示例，第二个是一个混合了两种函数并且增加了一个validator的示例。")
            }
        }
        // —— SpinBox（编辑会话由 TextField 双层承担——迁移后验证）——
        QoolControl {
            title: qsTr("数值步进（可编辑）")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    id: editSpinBox
                    Layout.fillWidth: true
                    editable: true
                    from: 0
                    to: 100
                    decimals: 1
                    stepSize: 0.5
                    value: 12.5
                    onAccepted: console.log("SpinBox accepted:", value)
                    onRejected: console.log("SpinBox rejected")
                }
            }
            QoolTip {
                text: qsTr("可编辑 SpinBox——点击进入编辑，Enter/失焦提交：合法值接受（value 更新），非法值拒绝回退（accepted/rejected 可监听）。")
            }
        }
    } //cc
}
