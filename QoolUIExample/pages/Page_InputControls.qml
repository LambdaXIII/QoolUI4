// 标准输入控件演示页：展示 Qool.Controls 重写的输入控件——EditableText
// （双层编辑会话/validator 校验/插拔转换——示例源自 Playground 调试
// 用例，置于页面最前）、ComboBox（标题、背景定制、QoolTip 说明）、
// SpinBox（步进/可编辑/wrap/自定义格式——同组 SectionBar 分段）以及
// SectionBar、Dial 等控件。
//
// 刻意设计（修复说明）：组合框的弹出方向取自
// listModel2.get(currentIndex).value——Qool.Controls.ComboBox（继承
// T.ComboBox）不提供 currentValue，valueRole 亦不存在，方向枚举值
// （Qore.Covered/Above/Below）必须经 ListModel 行对象取回。
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

        // —— EditableText 系列（源自 Playground 调试用例）——
        QoolControl {
            title: qsTr("试试输入你的名字")
            width: 200
            contentItem: ColumnLayout {
                EditableText {
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
                text: qsTr("QoolUI提供了一个**高定**版本的EditableText。基本用法和标准的类似，但是实现了更多可能性。")
            }
        }

        // —— EditableText + validator 用例（DoubleValidator 0~100 两位小数）——
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
                EditableText {
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

                EditableText {
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

                EditableText {
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

            QoolTip {
                text: qsTr("挂接 Qt validator 家族（DoubleValidator/IntValidator/RegularExpressionValidator）——输入合法 Enter/失焦接受（边框反馈 *positive*）、非法拒绝（*negative*）。校验在编辑模型层进行，编辑层保持纯净。")
            }

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
                EditableText {
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
                EditableText {
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
                text: qsTr("EditableText可以使用*displayTextFromText*方法重新设定输出格式。*textFromEditText*可用于讲输入的内容转换为值。这两个方法是独立的，并不一定互为逆运算。\n本组示例中第一个是一个简单的示例，第二个是一个混合了两种函数并且增加了一个validator的示例。")
            }
        }

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

        // —— SpinBox 系列（一组——编辑会话由 EditableText 双层承担）——
        QoolControl {
            title: qsTr("整数步进")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    Layout.fillWidth: true
                    decimals: 0
                    stepSize: 1
                    from: 0
                    to: 10
                    value: 3
                }
            }
        }

        QoolControl {
            title: qsTr("小数步进")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    Layout.fillWidth: true
                    decimals: 2
                    stepSize: 0.5
                    from: 0
                    to: 100
                    value: 12.5
                }
            }
        }

        QoolControl {
            title: qsTr("可编辑")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
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

        QoolControl {
            title: qsTr("wrap 回环")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    Layout.fillWidth: true
                    wrap: true
                    from: 0
                    to: 10
                    stepSize: 1
                    value: 10
                }
            }
            QoolTip {
                text: qsTr("wrap: true——到达 to 后再步进回 from（回环）。")
            }
        }

        QoolControl {
            title: qsTr("自定义格式")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    Layout.fillWidth: true
                    from: 0
                    to: 10
                    decimals: 0
                    value: 2
                    // 显示/解析配对覆写（官方扩展点——实例可设）：
                    // 显示带单位、解析去单位。注意：编辑会话按默认格式
                    // （validator 不认自定义文本——可编辑 + 自定义格式需
                    // 同时覆写 validator，超演示范围——本用例仅展示显示覆写）
                    textFromValue: function (v, locale, decimals) {
                        return v + " 倍";
                    }
                    valueFromText: function (text, locale) {
                        return Number(text.replace(" 倍", ""));
                    }
                }
            }
            QoolTip {
                text: qsTr("textFromValue/valueFromText 配对覆写——自定义显示/解析格式（官方扩展点）。")
            }
        }

        QoolControl {
            title: qsTr("禁用态")
            width: 200
            contentItem: ColumnLayout {
                SpinBox {
                    Layout.fillWidth: true
                    from: 0
                    to: 10
                    stepSize: 1
                    value: 3
                    enabled: false
                }
            }
        }

        SectionBar {
            width: parent.width
        }

        Dial {}
    } //cc
}
