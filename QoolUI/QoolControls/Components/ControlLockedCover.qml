import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Qool

Item {
    id: root
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property alias barWidth: bars.barWidth
    property alias spacing: bars.barSpacing
    property alias angel: bars.angle
    property int cycleDuration: 2000

    property color color: Qore.style.negative

    anchors {
        fill: parent
        topMargin: parent.topInset
        leftMargin: parent.leftInset
        bottomMargin: parent.bottomInset
        rightMargin: parent.rightInset
    }

    z: 90
    clip: true

    opacity: parent.enabled ? 0 : 1
    BasicNumberBehavior on opacity {}

    ParallelVerticalBars {
        id: bars

        angle: 30
        barWidth: 10
        barSpacing: 10

        width: root.width + barOffset * 3
        height: root.height
        strokeWidth: 0
        x: 0 - barOffset

        // color: Style.negativeColor
        gradient: LinearGradient {
            y1: 0
            y2: root.height
            GradientStop {
                position: 0.2
                color: "transparent"
            }
            GradientStop {
                position: 0.9
                color: Qt.alpha(root.color, 0.4)
            }
        }
    }

    NumberAnimation {
        id: scrollingAnime
        duration: root.cycleDuration
        target: bars
        property: "x"
        from: 0 - bars.barOffset * 2
        to: 0 - bars.barOffset
        running: true
        loops: Animation.Infinite
        paused: !(root.visible && root.animationEnabled)
    }
}
