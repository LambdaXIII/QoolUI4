// 契约：userInteracting 按下置 true/释放置 false，消费方在 onPositionChanged 检查。
pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

MouseArea {
    id: root
    property bool userInteracting: false

    anchors.fill: parent

    cursorShape: userInteracting ? Qt.BlankCursor : Qt.CrossCursor

    preventStealing: true
    propagateComposedEvents: true

    onPressed: {
        userInteracting = true
    }

    onReleased: {
        userInteracting = false
    }
}
