import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

GridLayout {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Cyan
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    }

    ChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Magenta
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    }

    ChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Yellow
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    }

    ChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorHQ.Black
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    }
}
