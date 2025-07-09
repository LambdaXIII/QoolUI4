import QtQuick
import QtQuick.Controls
import Qool

NumberAnimation {
    id: root

    readonly property ParallelVerticalBars targetBars: target as ParallelVerticalBars

    property real offsetStart: 0
    property real offsetMove: targetBars.barOffset

    duration: Style.movementDuration * 5
    property: "offset"

    from: offsetStart
    to: offsetStart + (offsetMove - offsetMove / duration)
    loops: Animation.Infinite

    running: true
}
