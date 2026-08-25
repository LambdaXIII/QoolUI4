
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

ColumnLayout {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property bool showAlpha: true

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 5

    ColorChannelEdit {
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSVHue
        colorAssistant: root.colorAssistant
    } //hueEdit

    ColorChannelEdit {
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

    ColorChannelControl {
        id: valueControl
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.HSVValue
        colorAssistant: root.colorAssistant
    } //valueControl

    ColorChannelControl {
        id: alphaControl
        visible: root.showAlpha
        Layout.fillWidth: true
        animationEnabled: root.animationEnabled
        channel: ColorHQ.Alpha
        colorAssistant: root.colorAssistant
    } //alphaControl
}
