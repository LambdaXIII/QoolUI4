// HSL 面板：饱和度/明度编辑行 → HSLBox 表面 → 色相/透明度组合行。
// 色相组合行用 HSVHue 通道（HSLBox 驱动 hslHueF，两域经 color 同步）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

ColumnLayout {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property bool showAlpha: true

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

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

    HSLBox {
        id: hslBox
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        animationEnabled: root.animationEnabled
        colorAssistant: root.colorAssistant
    } //hslBox

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
