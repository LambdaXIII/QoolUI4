import QtQuick
import QtQuick.Window
import "_private"

Window {
    id: root

    property alias background: bgShape
    property alias backgroundSettings: bgShape.settings

    visible: true
    minimumWidth: 200
    minimumHeight: 200

    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"
    QoolWindowBG {
        id: bgShape
    }
}
