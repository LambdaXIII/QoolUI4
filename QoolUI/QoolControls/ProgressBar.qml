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
    property int horizontalAlignment: Qt.AlignLeft

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

            width: parent.width + barOffset * 2
            height: parent.height
        }
        ParallelVerticalBarsAnimation {
            target: bars
            duration: root.cycleDuration * 2
            paused: root.indeterminate || (!root.Style.animationEnabled)
            running: true
        }
    }

    contentItem: Item {
        id: mainItem
        implicitWidth: 100
        implicitHeight: 20
        OctagonRoundedShape {
            id: progressShape
            height: parent.height
            width: parent.width
            settings {
                borderWidth: root.settings.borderWidth
                borderColor: root.settings.borderColor
                fillColor: Style.highlight
                cutSize: height / 2
                cutSizesLocked: true
            }
            fillItem: face
        }
    }

    SmartObject {
        id: pCtrl
        readonly property real visualWidth: (mainItem.width - mainItem.height) * root.visualPosition
        readonly property real visualX: {
            switch (root.horizontalAlignment) {
            case Qt.AlignLeft:
                return 0
            case Qt.AlignRight:
                return mainItem.width - visualWidth
            default:
                return (mainItem.width - visualWidth) / 2
            }
        }

        readonly property real indeterminateWidth: Math.min(
                                                       200,
                                                       mainItem.width * 0.35)
        property bool visualBindingEnabled: !root.indeterminate
        Binding {
            when: pCtrl.visualBindingEnabled
            progressShape.shapeControl.width: pCtrl.visualWidth
            progressShape.shapeControl.offsetX: pCtrl.visualX
            restoreMode: Binding.RestoreNone
        }

        ParallelAnimation {
            id: indeterminateIn
            onStarted: {
                pCtrl.visualBindingEnabled = false
                if (!root.Style.animationEnabled)
                    complete()
            }
            NumberAnimation {
                target: progressShape.shapeControl
                property: "width"
                to: pCtrl.indeterminateWidth
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.shapeControl
                property: "offsetX"
                to: 0
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
        }
        ParallelAnimation {
            id: indeterminateOut
            onStarted: {
                if (!root.Style.animationEnabled)
                    complete()
            }

            onFinished: pCtrl.visualBindingEnabled = true
            NumberAnimation {
                target: progressShape.shapeControl
                property: "width"
                to: pCtrl.visualWidth
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.shapeControl
                property: "offsetX"
                to: pCtrl.visualX
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
        }
        SequentialAnimation {
            id: indeterminateLoop
            loops: Animation.Infinite
            NumberAnimation {
                target: progressShape.shapeControl
                property: "offsetX"
                to: mainItem.width - pCtrl.indeterminateWidth
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
            NumberAnimation {
                target: progressShape.shapeControl
                property: "offsetX"
                to: 0
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
        }

        NumberAnimation {
            id: alignmentAnime
            target: progressShape.shapeControl
            property: "offsetX"
            to: pCtrl.visualX
            duration: Style.transitionDuration
            easing.type: Easing.OutBack
            onStarted: pCtrl.visualBindingEnabled = false
            onFinished: pCtrl.visualBindingEnabled = true
        }

        Connections {
            target: root
            function onIndeterminateChanged() {
                if (root.indeterminate) {
                    indeterminateIn.start()
                    indeterminateLoop.start()
                } else {
                    indeterminateLoop.stop()
                    indeterminateOut.start()
                }
            }
        }
    }
}
