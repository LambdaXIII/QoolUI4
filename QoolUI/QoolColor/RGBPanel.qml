import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

GridLayout {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property bool showAlpha: false
    property bool showBrightness: false

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ColorChannelControl {
        visible: root.showBrightness
        colorAssistant: root.colorAssistant
        channel: ColorHQ.HSVValue
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    }

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Red
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    }

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Green
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    }

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Blue
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    }

    ColorChannelControl {
        visible: root.showAlpha
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Alpha
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 4
    }
}
