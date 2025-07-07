import QtQuick
import Qool

Item {
    id: root
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property color highColor: Style.highlight
    property color lowColor: Style.highlightedText
    property list<string> words: Style.papaWords

    property bool rounded: false

    property OctagonSettings settings: parent?.backgroundSettings
                                       ?? internalSettings

    z: 85
    anchors {
        fill: parent
        topMargin: parent.topInset
        bottomMargin: parent.bottomInset
        leftMargin: parent.leftInset
        rightMargin: parent.rightInset
    }

    OctagonSettings {
        id: internalSettings
    }

    Component {
        id: baseBox
        QoolBox {
            settings {
                cutSizes: root.settings.cutSizes
                borderWidth: root.settings.borderWidth
                borderColor: root.highColor
            }
            fillItem: lightBeam
        }
    }

    Component {
        id: roundedBox
        QoolRoundedBox {
            settings {
                cutSizes: root.settings.cutSizes
                borderWidth: root.settings.borderWidth
                borderColor: root.highColor
            }
            fillItem: lightBeam
        }
    }

    Loader {
        id: loader
        sourceComponent: root.rounded ? roundedBox : baseBox
        anchors.fill: parent
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
