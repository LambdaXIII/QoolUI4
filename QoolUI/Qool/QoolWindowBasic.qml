import QtQuick
import QtQuick.Window
import "_private"
import Qool

Window {
    id: root

    property alias background: bgShape
    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.windowCutSize
        borderWidth: root.Style.windowBorderWidth
        borderColor: root.Style.accent
        fillColor: root.Style.window
    }

    visible: true
    minimumWidth: 200
    minimumHeight: 200

    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"
    QoolWindowBG {
        id: bgShape
        settings: root.backgroundSettings
    }
}
