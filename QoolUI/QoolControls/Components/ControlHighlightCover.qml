import QtQuick
import Qool

Item {
    id: root

    property color highColor: Style.highlight
    property color lowColor: Style.highlightedText
    property list<string> words: Style.papaWords

    property bool rounded: false

    property QoolBoxSettings settings: parent?.backgroundSettings
                                       ?? internalSettings

    z: 85
    anchors {
        fill: parent
        topMargin: parent.topInset
        bottomMargin: parent.bottomInset
        leftMargin: parent.leftInset
        rightMargin: parent.rightInset
    }

    QoolBoxSettings {
        id: internalSettings
    }

    QoolBox {
        id: baseBox
        anchors.fill: parent
        settings {
            cutSizeTL: root.settings.cutSizeTL
            cutSizeTR: root.settings.cutSizeTR
            cutSizeBL: root.settings.cutSizeBL
            cutSizeBR: root.settings.cutSizeBR
            borderWidth: root.settings.borderWidth
            borderColor: root.highColor
            curved: root.settings.curved
        }
        fillItem: lightBeam
    }

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

    BasicNumberBehavior on opacity {
        enabled: root.Style.animationEnabled
    }
}
