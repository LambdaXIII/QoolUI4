// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前内容：EditableText 密码回显（echoMode）调试用例（2026-08-11，
// spec .scratch/editabletext——T2 验证项 2）。每个用例旁显示实时
// displayText 以验证掩码派生结果。
import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Controls
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("EditableText 密码回显调试用例")

    // 页面高度随内容（同级 Column 页面惯例——不覆盖则默认=视口高，
    // Flickable 无法滚动到下部用例）
    implicitHeight: cc.implicitHeight

    Column {
        id: cc

        spacing: 15

        // —— 场景 1：Password——非编辑态 displayText 掩码；进入编辑会话
        //    键入新字符短暂明文（passwordMaskDelay）后掩码 ——
        QoolControl {
            title: qsTr("Password：掩码显示 + 编辑短暂明文")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfPassword
                    Layout.fillWidth: true
                    text: "secret123"
                    echoMode: TextInput.Password
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText：%1").arg(tfPassword.displayText)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }

        // —— 场景 2：NoEcho——完全无回显（displayText 空串）——
        QoolControl {
            title: qsTr("NoEcho：完全无回显")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfNoEcho
                    Layout.fillWidth: true
                    text: "invisible"
                    echoMode: TextInput.NoEcho
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText 长度：%1").arg(tfNoEcho.displayText.length)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }

        // —— 场景 3：PasswordEchoOnEdit——平时掩码、编辑期间明文 ——
        QoolControl {
            title: qsTr("PasswordEchoOnEdit：平时掩码、编辑明文")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfEchoOnEdit
                    Layout.fillWidth: true
                    text: "mixed123"
                    echoMode: TextInput.PasswordEchoOnEdit
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText：%1").arg(tfEchoOnEdit.displayText)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }

        // —— 场景 4：passwordCharacter 自定义（显式掩码字符）——
        QoolControl {
            title: qsTr("passwordCharacter：自定义掩码字符")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfCustomChar
                    Layout.fillWidth: true
                    text: "custom"
                    echoMode: TextInput.Password
                    passwordCharacter: "█"
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText：%1").arg(tfCustomChar.displayText)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }

        // —— 场景 5：readOnly + Password——只读掩码展示（不可编辑）——
        QoolControl {
            title: qsTr("readOnly + Password：只读掩码展示")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfReadOnly
                    Layout.fillWidth: true
                    text: "locked456"
                    readOnly: true
                    echoMode: TextInput.Password
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText：%1").arg(tfReadOnly.displayText)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }

        // —— 场景 6：displayTextFromText 插拔 + Password——密码化作用于
        //    插拔派生结果之后 ——
        QoolControl {
            title: qsTr("插拔 + Password：密码化在插拔之后")
            width: 340
            contentItem: ColumnLayout {
                EditableText {
                    id: tfPlug
                    Layout.fillWidth: true
                    text: "user42"
                    echoMode: TextInput.Password
                    displayTextFromText: function (t) {
                        return "ID-" + t; // 插拔派生（保存→展示）→ 密码化其后
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("displayText（%1 字符）：%2")
                        .arg(tfPlug.displayText.length)
                        .arg(tfPlug.displayText)
                    color: Style.placeholderText
                    font.pixelSize: 11
                }
            }
        }
    } //cc
}
