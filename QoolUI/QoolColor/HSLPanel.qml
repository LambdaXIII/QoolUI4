// NOTE(迁移) v3 Qool.Color/HSLPanel.qml 迁移。
// 组合模式照迁：数字输入行（GridLayout + NumInput）→ HSLBox 表面 →
// 色相（ColorSlider_Hue）/ 透明度（ColorSlider_Alpha）滑块。
// 替换点：TextLineEdit → NumInput（数值约定 x>1→/1000+限幅 收拢为
//   NumInput.parseChannelValue，语义与 v3 面板内联 Connections 逐字一致）；
//   Style.textColor → Style.text、Style.highlightColor → Style.highlight、
//   PixelFont.normalFont → PixelFont.normal（见 T08/T10 style_mapping）。
// 交互照迁：HSLBox 拖动取色/双击重置（hue<0→0，然后 sat=1、ltn=0.5）、
//   ColorSlider_Hue 拖动/双击重置（0）、ColorSlider_Alpha 拖动/双击重置（1）、
//   showAlpha 控制透明度滑块显隐、animationEnabled 门控动画。
// 与 v3 的刻意差异：标签为排版文字（画面元素），不翻译；格式规范化。
// NOTE: 与 v3 一致，HSLBox 驱动 hslHueF/hslSaturationF/hslLightnessF，
//   ColorSlider_Hue 驱动 hsvHueF（两域经 colorAssistant.color 同步，v3 架构）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"
import "_private/NumTools.js" as Tools

ColumnLayout {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style），子件各自消费。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property bool showAlpha: true

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    GridLayout {
        columns: 2
        Layout.fillWidth: true
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
                satText.text: Tools.simplifyChannelNumber(
                                  root.colorAssistant.hslSaturationF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: satText.editing
                target: satText
                function onTextChanged() {
                    root.colorAssistant.hslSaturationF = satText.parseChannelValue(
                                                             satText.text)
                }
            }
        } //satText

        Text {
            text: "LIGHTNESS"
            font: PixelFont.normal
            color: Style.text
            Layout.leftMargin: 2
            Layout.fillWidth: true
        } //LIGHTNESS

        NumInput {
            id: lightnessText
            showUnderline: false
            font: PixelFont.normal
            color: Style.text
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 2
            Layout.preferredWidth: 72
            Binding {
                when: !lightnessText.editing
                lightnessText.text: Tools.simplifyChannelNumber(
                                        root.colorAssistant.hslLightnessF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: lightnessText.editing
                target: lightnessText
                function onTextChanged() {
                    root.colorAssistant.hslLightnessF = lightnessText.parseChannelValue(
                                                            lightnessText.text)
                }
            }
        } //lightnessText
    } //数字输入行

    // HSLBox：拖动取色（sat/ltn → hslSaturationF/hslLightnessF）；
    // 双击重置为 sat=1、ltn=0.5（纯色中点——与 HSVWheel 重置到无彩色的
    // 语义不同，v3 原样，勿统一）。
    HSLBox {
        id: hslBox
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        animationEnabled: root.animationEnabled
        colorAssistant: root.colorAssistant
    } //hslBox

    ColorSlider_Hue {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
    } //hueSlider

    ColorSlider_Alpha {
        id: alphaSlider
        visible: root.showAlpha
        Layout.fillWidth: true
        colorAssistant: root.colorAssistant
        animationEnabled: root.animationEnabled
    } //alphaSlider
}
