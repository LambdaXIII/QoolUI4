import QtQuick
import QtQuick.Window
import QtQuick.Controls
import "_private"

Window {
    id: root

    property bool animationEnabled: true
    readonly property OctagonSettings backgroundSettings: OctagonSettings {
        cutSizeTL: 60
        borderWidth: 1
        fillColor: palette.base
        borderColor: palette.accent
    }

    visible: true
    minimumWidth: 200
    minimumHeight: 200
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"

    QoolWindowBG {
        id: bgShape
        anchors.fill: parent
        settings: root.backgroundSettings
        onWannaMove: (dx, dy) => {
            root.x = root.x + dx;
            root.y = root.y + dy;
        }
    }

    Button {
        text: "X"
        onClicked: {
            root.close();
        }
    }
}
