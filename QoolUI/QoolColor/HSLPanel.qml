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

    ChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSLSaturation
        colorAssistant: root.colorAssistant
    } //saturationEdit

    ChannelEdit {
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

    ChannelControl {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    } //hueControl

    ChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.Alpha
        colorAssistant: root.colorAssistant
    } //alphaControl
}
