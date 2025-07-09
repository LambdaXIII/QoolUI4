import QtQuick
import QtQuick.Controls
import Qool

NumberAnimation {
    id: root

    readonly property ParallelVerticalBars targetBars: target as ParallelVerticalBars

    property real defaultX: 0 - targetBars.barOffset * 2
    property real offset: targetBars.barOffset

    target: parent
    duration: Style.movementDuration * 5
    property: "x"

    from: defaultX
    to: defaultX + offset
    loops: Animation.Infinite
}
