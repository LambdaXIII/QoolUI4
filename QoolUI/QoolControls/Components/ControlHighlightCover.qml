import QtQuick
import Qool

QoolBox {
    id: root

    property color highColor: palette.highlight
    property color lowColor: palette.highlightedText
    property var words: Qore.style.papaWords

    clip: true

    settings {
        cutSizes: parent.backgroundSettings.cutSizes
        borderWidth: parent.backgroundSettings.borderWidth
        borderColor: root.highColor
    }

    z: 85
    anchors {
        fill: parent
        topMargin: parent.topInset
        bottomMargin: parent.bottomInset
        leftMargin: parent.leftInset
        rightMargin: parent.rightInset
    }
    fillItem: lightBeam

    Rectangle {
        id: lightBeam
        anchors.fill: parent
        layer.enabled: true
        gradient: Gradient {
            orientation: Gradient.Vertical
            stops: [
                GradientStop {
                    position: 0.1
                    color: "transparent"
                },
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.highColor, 0.1)
                }
            ]
        }
    }

    BasicNumberBehavior on opacity {}
}
