import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

ColumnLayout {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property bool showAlpha: false

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    ColorChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSLSaturation
        colorAssistant: root.colorAssistant
    } //saturationEdit

    ColorChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSLLightness
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
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    } //hueControl

    ColorChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.Alpha
        colorAssistant: root.colorAssistant
    } //alphaControl
}
