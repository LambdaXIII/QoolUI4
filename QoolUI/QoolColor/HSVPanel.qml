// HSV 面板：数字输入行（GridLayout + NumInput）→ HSVWheel 表面 →
// 明度（ColorSlider_Value）/ 透明度（ColorSlider_Alpha）滑块。
// 交互：HSVWheel 拖动取色/双击重置（hue=0、sat=0）、滑块拖动/双击重置
//   （Value/Alpha 默认 1）、showAlpha 控制透明度滑块显隐、animationEnabled 门控动画。
// 刻意：标签为排版文字（画面元素），不翻译。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"
import "_private/NumTools.js" as Tools

ColumnLayout {
    id: root

    // 动画总开关：父级属性 → Style 传播，子件各自消费。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property bool showAlpha: true

    // 默认状态自洽：默认实例自带默认色，独立使用成立。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Text {
            text: "HUE"
            font: PixelFont.normal
            color: Style.text
            Layout.leftMargin: 2
            Layout.fillWidth: true
        } //HUE

        NumInput {
            id: hueText
            showUnderline: false
            font: PixelFont.normal
            color: Style.text
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 2
            Layout.preferredWidth: 72
            Binding {
                when: !hueText.editing
                hueText.text: Tools.simplifyChannelNumber(root.colorAssistant.hsvHueF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: hueText.editing
                target: hueText
                function onTextChanged() {
                    root.colorAssistant.hsvHueF = hueText.parseChannelValue(hueText.text);
                }
            }
        } //hueText

        Text {
            text: "SATURATION"
            font: PixelFont.normal
            color: Style.text
            Layout.leftMargin: 2
            Layout.fillWidth: true
        } //SATURATION

        NumInput {
            id: satText
            showUnderline: false
            font: PixelFont.normal
            color: Style.text
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 2
            Layout.preferredWidth: 72
            Binding {
                when: !satText.editing
                satText.text: Tools.simplifyChannelNumber(root.colorAssistant.hsvSaturationF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: satText.editing
                target: satText
                function onTextChanged() {
                    root.colorAssistant.hsvSaturationF = satText.parseChannelValue(satText.text);
                }
            }
        } //satText
    } //数字输入行

    // HSVWheel：拖动取色（hue/sat → hsvHueF/hsvSaturationF，圆外点击
    // 钳制到圆周）；双击重置为 hue=0、sat=0（无彩色）。
    HSVWheel {
        id: hsvSurface
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        animationEnabled: root.animationEnabled
        colorAssistant: root.colorAssistant
    } //hsvSurface

    ColorSlider_Value {
        id: valueSlider
        Layout.fillWidth: true
        colorAssistant: root.colorAssistant
        animationEnabled: root.animationEnabled
    } //valueSlider

    ColorSlider_Alpha {
        id: alphaSlider
        visible: root.showAlpha
        Layout.fillWidth: true
        colorAssistant: root.colorAssistant
        animationEnabled: root.animationEnabled
    } //alphaSlider
}
