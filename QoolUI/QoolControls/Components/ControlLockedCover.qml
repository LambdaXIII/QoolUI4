import QtQuick
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

    property color color: Style.negative

    property bool rounded: false
    property OctagonSettings settings: parent?.backgroundSettings
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

    OctagonSettings {
        id: internalSettings
    }

    Component {
        id: baseBox
        QoolBox {
            settings {
                cutSizes: root.settings.cutSizes
                borderWidth: root.settings.borderWidth
                borderColor: root.color
            }
            fillItem: barView
        }
    }

    Component {
        id: roundedBox
        QoolRoundedBox {
            settings {
                cutSizes: root.settings.cutSizes
                borderWidth: root.settings.borderWidth
                borderColor: root.color
            }
            fillItem: barView
        }
    }

    Loader {
        id: loader
        sourceComponent: root.rounded ? roundedBox : baseBox
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
}
