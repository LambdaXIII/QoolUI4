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
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    }

    ChannelEdit {
        Layout.fillWidth: true
        channel: ColorHQ.HSVSaturation
        colorAssistant: root.colorAssistant
    }

    HSVWheel {
        id: hsvSurface
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        colorAssistant: root.colorAssistant
    }

    ChannelControl {
        id: valueControl
        Layout.fillWidth: true
        channel: ColorHQ.HSVValue
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
