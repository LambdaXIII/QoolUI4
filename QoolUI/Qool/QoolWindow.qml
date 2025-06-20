pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import "_private"

Window {
    id: root

    property bool animationEnabled: transientParent?.animationEnabled ?? QoolConstants.animationEnabled
    property alias background: bgShape
    property alias settings: bgShape.settings
    property bool showCloseButton: true

    visible: true
    minimumWidth: 200
    minimumHeight: 200
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"

    QoolWindowBG {
        id: bgShape
        anchors.fill: parent
        onWannaMove: (dx, dy) => {
            root.x = root.x + dx;
            root.y = root.y + dy;
        }
    }

    Loader {
        id: closeButtonLoader
        sourceComponent: QoolWindowCloseButton {
            windowCutSize: root.settings.cutSize
            onClicked: root.close()
            visible: root.active
        }
        active: root.showCloseButton
    }
}
