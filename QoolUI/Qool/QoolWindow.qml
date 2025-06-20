pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import "_private"

QoolWindowBasic {
    id: root

    property bool showCloseButton: true

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
