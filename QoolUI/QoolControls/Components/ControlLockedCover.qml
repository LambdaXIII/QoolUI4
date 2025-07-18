import QtQuick
import QtQuick.Shapes
import Qool

Item {
    id: root

    property alias barWidth: bars.barWidth
    property alias spacing: bars.barSpacing
    property alias angel: bars.angle
    property int cycleDuration: 2000

    property color color: Style.negative

    property bool rounded: false
    property QoolBoxSettings settings: parent?.backgroundSettings
                                       ?? internalSettings

    z: 90
    anchors {
        fill: parent
        topMargin: parent.topInset
        leftMargin: parent.leftInset
        bottomMargin: parent.bottomInset
        rightMargin: parent.rightInset
    }

    opacity: parent.enabled ? 0 : 1
    BasicNumberBehavior on opacity {}

    QoolBoxSettings {
        id: internalSettings
    }

    QoolBox {
        id: baseBox
        settings {
            cutSizeTL: root.settings.cutSizeTL
            cutSizeTR: root.settings.cutSizeTR
            cutSizeBL: root.settings.cutSizeBL
            cutSizeBR: root.settings.cutSizeBR
            borderWidth: root.settings.borderWidth
            borderColor: root.color
            curved: root.settings.curved
        }
        fillItem: barView
        anchors.fill: parent
    }

    Item {
        id: barView
        anchors.fill: parent
        layer.enabled: true
        visible: false
        ParallelVerticalBars {
            id: bars

            angle: 30
            barWidth: 10
            barSpacing: 10

            width: parent.width + barOffset * 3
            height: parent.height
            strokeWidth: 0
            x: 0 - barOffset

            gradient: LinearGradient {
                y1: 0
                y2: parent.height
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.color, 0.05)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.color, 0.5)
                }
            }
        } //bars

        ParallelVerticalBarsAnimation {
            target: bars
            duration: root.cycleDuration
            paused: !(root.visible && root.Style.animationEnabled)
            running: true
        }
    }
}
