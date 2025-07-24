import QtQuick
import Qool
import Qool.File

DropArea {
    id: root

    property alias pattern: checker.pattern
    property alias patternBehavior: checker.patternBehavior
    property alias acceptDirs: checker.acceptDirs
    property alias acceptFiles: checker.acceptFiles

    readonly property bool containsAcceptable: containsDrag
                                               && pCtrl.isAcceptable

    signal accepted(var urls)

    QtObject {
        id: pCtrl
        property bool isAcceptable: false
    }

    UrlChecker {
        id: checker
    }

    Connections {
        target: root
        function onEntered(e) {
            pCtrl.isAcceptable = checker.containsAcceptableUrls(e.urls)
        }
        function onExited(e) {
            pCtrl.isAcceptable = false
        }
        function onDropped(e) {
            if (!pCtrl.isAcceptable)
                return
            let accepted_urls = checker.acceptableUrls(e.urls)
            root.accepted(accepted_urls)
        }
    }
}
