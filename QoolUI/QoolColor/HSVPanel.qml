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
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    } //hueEdit

    ChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSVSaturation
        colorAssistant: root.colorAssistant
    } //saturationEdit

    HSVWheel {
        id: hsvSurface
        Layout.fillWidth: true
        Layout.preferredHeight: 150
        Layout.fillHeight: true
        animationEnabled: root.animationEnabled
        colorAssistant: root.colorAssistant
    } //hsvSurface

    ChannelControl {
        id: valueControl
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSVValue
        colorAssistant: root.colorAssistant
    } //valueControl

    ChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.Alpha
        colorAssistant: root.colorAssistant
    } //alphaControl
}
