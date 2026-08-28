import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

ColumnLayout {
    id: root

    property bool showAlpha: false

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    ChannelEdit {
        Layout.fillWidth: true
        channel: ColorHQ.HSLSaturation
        colorAssistant: root.colorAssistant
    }

    ChannelEdit {
        Layout.fillWidth: true
        channel: ColorHQ.HSLLightness
        colorAssistant: root.colorAssistant
    }

    HSLBox {
        id: hslBox
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        colorAssistant: root.colorAssistant
    }

    ChannelControl {
        Layout.fillWidth: true
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    }

    ChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        channel: ColorHQ.Alpha
        colorAssistant: root.colorAssistant
    }
}
