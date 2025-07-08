import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

T.ProgressBar {
    id: root

    value: 0.5

    readonly property OctagonSettings settings: OctagonSettings {
        borderWidth: Style.controlBorderWidth
        borderColor: Style.mid
    }

    property int cycleDuration: Style.movementDuration * 2

    background: OctagonRoundedShape {
        implicitWidth: 100
        implicitHeight: 20
        settings {
            borderWidth: root.settings.borderWidth
            borderColor: root.settings.borderColor
            fillColor: Style.dark
            cutSize: height / 2
            cutSizesLocked: true
        }
    }

    Rectangle {
        id: face
        border.width: 0
        color: Style.mid
        anchors.fill: contentItem
        layer.enabled: true
        visible: false
        ParallelVerticalBars {
            id: bars
            strokeWidth: 0
            barWidth: 10
            barSpacing: 8
            gradient: LinearGradient {
                y1: 0
                y2: face.height
                GradientStop {
                    position: 0
                    color: Qt.lighter(Style.active.highlight, 1.5)
                }
                GradientStop {
                    position: 1
                    color: Qt.darker(Style.active.highlight, 1.5)
                }
            }

            width: parent.width
            height: parent.height
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
            paused: !(root.visible && root.Style.animationEnabled)
                    || duration <= 0 || root.indeterminate
        }
    }

    contentItem: Item {
        implicitWidth: 100
        implicitHeight: 20
        OctagonRoundedShape {
            id: progressShape
            width: parent.width * root.visualPosition
            height: parent.height
            settings {
                borderWidth: root.settings.borderWidth
                borderColor: root.settings.borderColor
                fillColor: Style.highlight
                cutSize: height / 2
                cutSizesLocked: true
            }
            fillItem: face
            visible: !root.indeterminate
        }

        OctagonRoundedShape {
            id: indeterminateShape
            width: Math.min(parent.width * 0.35, 150)
            height: parent.height
            settings {
                borderWidth: root.settings.borderWidth
                borderColor: root.settings.borderColor
                fillColor: Style.highlight
                cutSize: height / 2
                cutSizesLocked: true
            }
            fillItem: face
            visible: root.indeterminate
            SequentialAnimation {
                id: interAnime
                running: root.indeterminate
                loops: Animation.Infinite
                XAnimator {
                    target: indeterminateShape
                    duration: root.cycleDuration * 2
                    from: 0
                    to: target.parent.width - target.width
                }
                XAnimator {
                    target: indeterminateShape
                    duration: root.cycleDuration * 2
                    to: 0
                    from: target.parent.width - target.width
                }
            }
        }
    }
}
