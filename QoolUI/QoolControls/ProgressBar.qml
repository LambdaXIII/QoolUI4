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

    property real radius: Math.floor(height / 2)

    background: OctagonRoundedShape {
        implicitWidth: 100
        implicitHeight: 20
        settings {
            borderWidth: root.settings.borderWidth
            borderColor: root.settings.borderColor
            fillColor: Style.dark
            cutSize: root.radius
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
            width: parent.width
            height: parent.height
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
                cutSize: root.radius
                cutSizesLocked: true
            }
            fillItem: face
        }
    }

    SmartObject {
        id: pCtrl
        readonly property real visualWidth: (mainItem.width - root.radius) * root.visualPosition
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
            target: progressShape.control
            property: "width"
            value: pCtrl.visualWidth
            restoreMode: Binding.RestoreValue
        }
        Binding {
            when: pCtrl.visualBindingEnabled
            target: progressShape.control
            property: "offsetX"
            value: pCtrl.visualX
            restoreMode: Binding.RestoreValue
        }

        ParallelAnimation {
            id: indeterminateIn
            onStarted: {
                pCtrl.visualBindingEnabled = false
                if (!root.Style.animationEnabled)
                    complete()
            }
            NumberAnimation {
                target: progressShape.control
                property: "width"
                to: pCtrl.indeterminateWidth
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.control
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
                target: progressShape.control
                property: "width"
                to: pCtrl.visualWidth
                duration: Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.control
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
                target: progressShape.control
                property: "offsetX"
                to: mainItem.width - pCtrl.indeterminateWidth
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
            NumberAnimation {
                target: progressShape.control
                property: "offsetX"
                to: 0
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
        }

        NumberAnimation {
            id: alignmentAnime
            target: progressShape.control
            property: "offsetX"
            to: pCtrl.visualX
            duration: Style.transitionDuration
            easing.type: Easing.OutBack
            onStarted: pCtrl.visualBindingEnabled = false
            onFinished: pCtrl.visualBindingEnabled = true
        }

        function startIndeterminate() {
            indeterminateIn.start()
            indeterminateLoop.start()
        }

        function stopIndeterminate() {
            indeterminateLoop.stop()
            indeterminateOut.start()
        }

        function check_indeterminate() {
            if (root.indeterminate)
                startIndeterminate()
            else
                stopIndeterminate()
        }

        Connections {
            target: root
            function onIndeterminateChanged() {
                pCtrl.check_indeterminate()
            }
        }
    }

    Component.onCompleted: pCtrl.check_indeterminate()
}
