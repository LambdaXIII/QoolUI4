import QtQuick
import QtQuick.Layouts
import Qool

Item {
    id: root
    // enabled: false
    property list<string> colors: ["accent", "alternateBase", "base", "button", "buttonText", "dark", "highlight", "highlightedText", "light", "mid", "midlight", "placeholderText", "shadow", "text", "window", "windowText"]

    GridLayout {
        columns: 5
        Repeater {
            model: root.colors
            delegate: Rectangle {
                implicitWidth: 100
                implicitHeight: 35
                radius: 5
                color: palette[modelData]
                border.width: 1
                border.color: "#FFFFFF"
                Text {
                    text: modelData
                    anchors.centerIn: parent
                }
            }
        }
    }
}
