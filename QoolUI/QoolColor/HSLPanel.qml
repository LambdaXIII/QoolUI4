// HSL 面板：饱和度/明度通道编辑行（ColorChannelEdit）→ HSLBox 表面 →
// 色相（ColorChannelControl）/ 透明度（ColorChannelControl）组合行。
// 交互：HSLBox 拖动取色（sat/ltn → hslSaturationF/hslLightnessF，hue
//   外部驱动）、ColorChannelEdit/Control 编辑与拖动通道值、showAlpha
//   控制透明度组合行显隐、animationEnabled 门控动画。
// 刻意：标签为排版文字（channelTag），不翻译。
// NOTE: HSLBox 驱动 hslHueF/hslSaturationF/hslLightnessF，
//   色相组合行 channel=HSVHue（旧 ColorSlider_Hue 驱动 hsvHueF——
//   两域经 colorAssistant.color 同步，此处沿用）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

ColumnLayout {
    id: root

    // 动画总开关：父级属性 → Style 传播，子件各自消费。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property bool showAlpha: true

    // 默认状态自洽：默认实例自带默认色，独立使用成立。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    // 饱和度/明度通道编辑行（自带标签 channelTag，编辑与会话行为内化）。
    ColorChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorNameHQ.HSLSaturation
        colorAssistant: root.colorAssistant
    } //saturationEdit

    ColorChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorNameHQ.HSLLightness
        colorAssistant: root.colorAssistant
    } //lightnessEdit

    // HSLBox：拖动取色（sat/ltn → hslSaturationF/hslLightnessF，hue 外部驱动）。
    HSLBox {
        id: hslBox
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        animationEnabled: root.animationEnabled
        colorAssistant: root.colorAssistant
    } //hslBox

    // 色相组合行（channel=HSVHue——旧 ColorSlider_Hue 驱动 hsvHueF，沿用）。
    ColorChannelControl {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorNameHQ.HSVHue
        colorAssistant: root.colorAssistant
    } //hueControl

    ColorChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorNameHQ.Alpha
        colorAssistant: root.colorAssistant
    } //alphaControl
}
