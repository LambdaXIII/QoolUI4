import QtQuick
import Qool
import Qool.File
import Qool.Controls

QoolControl {
    id: root

    property alias pattern: dropZone.pattern
    property alias patternBehavior: dropZone.patternBehavior
    property alias acceptDirs: dropZone.acceptDirs
    property alias acceptFiles: dropZone.acceptFiles

    readonly property bool containsDrag: dropZone.containsDrag
    readonly property bool containsAcceptable: dropZone.containsAcceptable

    signal accepted(var urls)

    title: "Drop files here"

    contentItem: Item {
        implicitWidth: 100
        implicitHeight: 100
        clip: true
    }

    QtObject {
        id: pCtrl
        property color indicatorColor: {
            if (dropZone.containsAcceptable)
                return root.Style.positive
            if (dropZone.containsDrag)
                return root.Style.negative
            return root.Style.highlight
        }
        property real indicatorOpacity: dropZone.containsDrag ? 1 : 0
    }

    FileDropArea {
        id: dropZone
        parent: root.background
        containmentMask: root.background
        anchors.fill: parent
        onAccepted: urls => root.accepted(urls)
    }

    QoolBox {
        id: indicator
        anchors.fill: parent
        z: 30
        settings {
            borderWidth: root.backgroundSettings.borderWidth
            borderColor: pCtrl.indicatorColor
            fillColor: Qt.alpha(pCtrl.indicatorColor, 0.1)
        }
        opacity: pCtrl.indicatorOpacity
        CutSizeBinding {
            from: root.backgroundSettings
            to: indicator.settings
        }
        BasicColorBehavior on settings.borderColor {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
        BasicColorBehavior on settings.fillColor {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
        BasicNumberBehavior on opacity {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
    }
}
