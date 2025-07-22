import QtQuick
import Qool
import Qool.File
import Qool.Controls

QoolControl {
    id: root

    property alias pattern: checker.pattern
    property alias patternBehavior: checker.patternBehavior

    property alias acceptDirs: checker.acceptDirs
    property alias acceptFiles: checker.acceptFiles

    readonly property bool containsDrag: zone.containsDrag
    readonly property bool isAcceptable: zone.isAcceptable

    signal accepted(var urls)

    title: "Drop files here"

    contentItem: Item {
        implicitWidth: 100
        implicitHeight: 100
        clip: true
    }

    UrlChecker {
        id: checker
    }

    QtObject {
        id: pCtrl
        property color indicatorColor: root.Style.highlight
        property real indicatorOpacity: zone.containsDrag ? 1 : 0
    }

    DropArea {
        id: zone
        enabled: root.enabled
        anchors.fill: parent
        z: 50
        containmentMask: root.containmentMask

        property bool isAcceptable: false

        onEntered: e => {
                       pCtrl.indicatorColor = root.Style.highlight;
                       zone.isAcceptable = checker.containsAcceptableUrls(e.urls);
                       pCtrl.indicatorColor = zone.isAcceptable ? root.Style.positive :
                                                                  root.Style.negative;
                   }

        onExited: e => {
                      zone.isAcceptable = false;
                  }
        onDropped: e => {
                       if (!zone.isAcceptable)
                       return;
                       let accepted_urls = checker.acceptableUrls(e.urls);
                       root.accepted(accepted_urls);
                   }
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
