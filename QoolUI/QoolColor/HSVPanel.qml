// NOTE(迁移) v3 Qool.Color/HSVPanel.qml 迁移。
// 组合模式照迁：数字输入行（GridLayout + NumInput）→ HSVWheel 表面 →
// 明度（ColorSlider_Value）/ 透明度（ColorSlider_Alpha）滑块。
// 替换点：TextLineEdit → NumInput（数值约定 x>1→/1000+限幅 收拢为
//   NumInput.parseChannelValue，语义与 v3 面板内联 Connections 逐字一致）；
//   Style.textColor → Style.text、Style.highlightColor → Style.highlight、
//   PixelFont.normalFont → PixelFont.normal（见 T08/T10 style_mapping）。
// 交互照迁：HSVWheel 拖动取色/双击重置（hue=0、sat=0）、滑块拖动/双击重置
//   （Value/Alpha 默认 1）、showAlpha 控制透明度滑块显隐、animationEnabled 门控动画。
// 与 v3 的刻意差异：标签文本加 qsTr（AGENTS 规范）；格式规范化（v3 缩进怪癖）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"
import "_private/NumTools.js" as Tools

/*!
    \qmltype HSVPanel
    \inqmlmodule Qool.Color
    \brief HSV 色彩空间面板（v3 HSVPanel 迁移）：色相/饱和度数字输入 + HSV 渐变轮 + 明度/透明度滑块。

    自顶向下组合：
    \list 1
    \li 数字输入行：HUE / SATURATION 两个通道输入（\l NumInput）。
    \li \l {HSVWheel}{HSVWheel} 表面：色相 × 饱和度渐变轮。
    \li \l {ColorSlider_Value}{ColorSlider_Value} 明度滑块。
    \li \l {ColorSlider_Alpha}{ColorSlider_Alpha} 透明度滑块（\c showAlpha 控制显隐）。
    \endlist

    \section1 交互（v3 照迁）

    \list
    \li 表面：按住拖动取色（色相/饱和度分别写入 \c colorAssistant.hsvHueF /
        \c hsvSaturationF，圆外点击钳制到圆周）；双击重置为 hue=0、sat=0
        （无彩色）。
    \li 滑块：拖动改值（明度/透明度）；双击重置为各自默认值 1。
    \li 数字输入：点击进入编辑，回车或失焦写回；输入 \c x > 1 时按
        \c x / 1000 处理（见下"输入约定"）。
    \endlist

    \section1 输入约定（易误解，特别说明）

    通道输入沿用 v3 数值约定：\b 输入 \c x > 1 时按 \c x / 1000 处理——
    允许直接键入 0..1000 的整数表示 0..1 的比例（如 \c 350 表示 0.35），
    结果限幅到 [0, 1]。这是 v3 面板行为，\b 不是 bug，勿"修复"为普通除法。
    实现收拢在 \l {NumInput::parseChannelValue}{NumInput.parseChannelValue}。

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Style.highlight }}——独立使用（不注入）即成立。
    面板本身不设默认尺寸（v3 同），宿主决定宽高与布局权重。

    \section1 属性

    \qmlproperty ColorAssistant HSVPanel::colorAssistant
    颜色数据源（v3 同名 API 照迁）。默认自带 \c Style.highlight 的实例；
    宿主可注入共享 \l ColorAssistant（多面板同步同一实例）。

    \qmlproperty bool HSVPanel::showAlpha
    是否显示透明度滑块，默认 \c true。

    \qmlproperty bool HSVPanel::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}（v4 惯例）。
    为 false 时表面/滑块动画即时完成。
*/
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
            text: qsTr("HUE")
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
                hueText.text: Tools.simplifyChannelNumber(
                                  root.colorAssistant.hsvHueF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: hueText.editing
                target: hueText
                function onTextChanged() {
                    root.colorAssistant.hsvHueF = hueText.parseChannelValue(
                                                      hueText.text)
                }
            }
        } //hueText

        Text {
            text: qsTr("SATURATION")
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
                                  root.colorAssistant.hsvSaturationF)
                restoreMode: Binding.RestoreNone
            }
            Connections {
                enabled: satText.editing
                target: satText
                function onTextChanged() {
                    root.colorAssistant.hsvSaturationF = satText.parseChannelValue(
                                                             satText.text)
                }
            }
        } //satText
    } //数字输入行

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
