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
// 与 v3 的刻意差异：标签文本加 qsTr（AGENTS 规范）；格式规范化。
// NOTE: 与 v3 一致，HSLBox 驱动 hslHueF/hslSaturationF/hslLightnessF，
//   ColorSlider_Hue 驱动 hsvHueF（两域经 colorAssistant.color 同步，v3 架构）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"
import "_private/NumTools.js" as Tools

/*!
    \qmltype HSLPanel
    \inqmlmodule Qool.Color
    \brief HSL 色彩空间面板（v3 HSLPanel 迁移）：饱和度/亮度数字输入 + HSL 渐变盒 + 色相/透明度滑块。

    自顶向下组合：
    \list 1
    \li 数字输入行：SATURATION / LIGHTNESS 两个通道输入（\l NumInput）。
    \li \l {HSLBox}{HSLBox} 表面：饱和度 × 亮度渐变盒。
    \li \l {ColorSlider_Hue}{ColorSlider_Hue} 色相滑块。
    \li \l {ColorSlider_Alpha}{ColorSlider_Alpha} 透明度滑块（\c showAlpha 控制显隐）。
    \endlist

    \section1 交互（v3 照迁）

    \list
    \li 表面：按住拖动取色（饱和度/亮度写入 \c colorAssistant.hslSaturationF /
        \c hslLightnessF）；双击重置为 sat=1、ltn=0.5（纯色中点——与
        HSVWheel 重置到无彩色的语义不同，v3 原样，勿统一）。
    \li 色相滑块：拖动改色相；双击重置为 0。
    \li 透明度滑块：拖动改透明度；双击重置为 1。
    \li 数字输入：点击进入编辑，回车或失焦写回；输入 \c x > 1 时按
        \c x / 1000 处理（见下"输入约定"）。
    \endlist

    \section1 输入约定（易误解，特别说明）

    通道输入沿用 v3 数值约定：\b 输入 \c x > 1 时按 \c x / 1000 处理——
    允许直接键入 0..1000 的整数表示 0..1 的比例（如 \c 350 表示 0.35），
    结果限幅到 [0, 1]。这是 v3 面板行为，\b 不是 bug，勿"修复"为普通除法。
    实现收拢在 \l {NumInput::parseChannelValue}{NumInput.parseChannelValue}。

    \section1 易误解点（v3 架构照迁）

    \list
    \li \l {ColorSlider_Hue}{ColorSlider_Hue} 操作的是 \c hsvHueF 而非
        \c hslHueF（色相环两端相接语义在两域等价，经 \c colorAssistant.color
        全空间同步）；\l {HSLBox}{HSLBox} 操作 hsl 域。两域并存是 v3 原样。
    \li 色相滑块对无效色相（\c hsvHueF < 0）的处置（保持饱和度）在滑块内部，
        本面板照迁不干预。
    \endlist

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Style.highlight }}——独立使用（不注入）即成立。
    面板本身不设默认尺寸（v3 同），宿主决定宽高与布局权重。

    \section1 属性

    \qmlproperty ColorAssistant HSLPanel::colorAssistant
    颜色数据源（v3 同名 API 照迁）。默认自带 \c Style.highlight 的实例；
    宿主可注入共享 \l ColorAssistant（多面板同步同一实例）。

    \qmlproperty bool HSLPanel::showAlpha
    是否显示透明度滑块，默认 \c true。

    \qmlproperty bool HSLPanel::animationEnabled
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
            text: qsTr("LIGHTNESS")
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
