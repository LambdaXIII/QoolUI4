import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

// indeterminate 运动不随 animationEnabled 门控（刻意设计）：往复循环是
// "不定进度模式"的功能语义（模式本身通过运动表达），动画门控只影响
// 装饰类效果。详细契约见 docs/reference/Qool.Controls/ProgressBar.md。

T.ProgressBar {
    id: root

    value: 0.5

    property int cycleDuration: root.Style.movementDuration * 2
    property int horizontalAlignment: Qt.AlignLeft

    property real radius: Math.floor(height / 2)

    property color highlightColor: Style.active.highlight
    property color alternateHighlightColor: Qt.alpha(highlightColor, 0.2)
    property color borderColor: Style.active.mid
    property color backgroundColor: Style.active.dark

    readonly property QoolBoxSettings settings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.mid
        fillColor: root.backgroundColor
        cutSizeTL: root.radius
        cutSizeTR: root.radius
        cutSizeBL: root.radius
        cutSizeBR: root.radius
    }

    // 变体消费 control.settings（spec D5）——两处几何各自注入 control
    //（target = 各自 Shape，几何源一致时也可共享）。
    readonly property QoolBoxShapeControl bgControl: QoolBoxShapeControl {
        target: bgShape
        settings: root.settings
    }
    readonly property QoolBoxShapeControl progressControl: QoolBoxShapeControl {
        target: progressShape
        settings: root.settings
    }

    background: OctagonCurvedShape {
        id: bgShape
        implicitWidth: 100
        implicitHeight: 20
        control: root.bgControl
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
                    color: root.highlightColor
                }
                GradientStop {
                    position: 1
                    color: root.alternateHighlightColor
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
        OctagonCurvedShape {
            id: progressShape
            height: parent.height
            width: parent.width
            control: root.progressControl
            fillItem: face
        }
    }

    SmartObject {
        id: pCtrl
        readonly property real visualWidth: (mainItem.width - root.radius)
                                            * root.visualPosition
        readonly property real visualX: {
            switch (root.horizontalAlignment) {
            case Qt.AlignLeft:
                return 0;
            case Qt.AlignRight:
                return mainItem.width - visualWidth;
            default:
                return (mainItem.width - visualWidth) / 2;
            }
        }

        readonly property real indeterminateWidth: Math.min(200, mainItem.width * 0.35)
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
            target: progressShape.control.settings
            property: "offsetX"
            value: pCtrl.visualX
            restoreMode: Binding.RestoreValue
        }

        ParallelAnimation {
            id: indeterminateIn
            onStarted: {
                pCtrl.visualBindingEnabled = false;
                if (!root.Style.animationEnabled)
                    complete();
            }
            NumberAnimation {
                target: progressShape.control
                property: "width"
                to: pCtrl.indeterminateWidth
                duration: root.Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.control.settings
                property: "offsetX"
                to: 0
                duration: root.Style.transitionDuration
                easing.type: Easing.OutBack
            }
        }
        ParallelAnimation {
            id: indeterminateOut
            onStarted: {
                if (!root.Style.animationEnabled)
                    complete();
            }

            onFinished: pCtrl.visualBindingEnabled = true
            NumberAnimation {
                target: progressShape.control
                property: "width"
                to: pCtrl.visualWidth
                duration: root.Style.transitionDuration
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: progressShape.control.settings
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
                target: progressShape.control.settings
                property: "offsetX"
                to: mainItem.width - pCtrl.indeterminateWidth
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
            NumberAnimation {
                target: progressShape.control.settings
                property: "offsetX"
                to: 0
                duration: root.cycleDuration * 2
                easing.type: Easing.OutSine
            }
        }

        NumberAnimation {
            id: alignmentAnime
            target: progressShape.control.settings
            property: "offsetX"
            to: pCtrl.visualX
            duration: root.Style.transitionDuration
            easing.type: Easing.OutBack
            onStarted: pCtrl.visualBindingEnabled = false
            onFinished: pCtrl.visualBindingEnabled = true
        }

        function startIndeterminate() {
            indeterminateIn.start();
            indeterminateLoop.start();
        }

        function stopIndeterminate() {
            indeterminateLoop.stop();
            indeterminateOut.start();
        }

        function check_indeterminate() {
            if (root.indeterminate)
                startIndeterminate();
            else
                stopIndeterminate();
        }

        Connections {
            target: root
            function onIndeterminateChanged() {
                pCtrl.check_indeterminate();
            }
        }
    }

    Component.onCompleted: pCtrl.check_indeterminate()
}
