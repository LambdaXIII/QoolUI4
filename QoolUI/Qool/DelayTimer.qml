import QtQuick
import Qool

SmartObject {
    id: root

    property alias interval: timer.interval
    readonly property bool running: timer.running

    signal aboutToStart
    signal started
    signal finished

    Timer {
        id: timer
        onTriggered: root.finished()
    }

    function start() {
        root.aboutToStart();
        timer.start();
        root.started();
    }

    function restart() {
        if (!timer.running)
            root.aboutToStart();
        timer.restart();
        root.started();
    }
}
