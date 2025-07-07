import QtQuick
import Qool

Item {
    id: root

    property color highColor: Style.highlight
    property color lowColor: Style.highlightedText
    property list<string> words: Style.papaWords

    property bool rounded: false

    property OctagonSettings settings: parent?.backgroundSettings
                                       ?? internalSettings

    z: 90
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
                borderColor: root.lowColor
            }
            fillItem: papa
        }
    }

    Component {
        id: roundedBox
        QoolRoundedBox {
            settings {
                cutSizes: root.settings.cutSizes
                borderWidth: root.settings.borderWidth
                borderColor: root.lowColor
            }
            fillItem: papa
        }
    }

    Loader {
        id: loader
        sourceComponent: root.rounded ? roundedBox : baseBox
        anchors.fill: parent
    }

    PaPaWall {
        id: papa
        anchors.fill: parent
        visible: false
        layer.enabled: true
        highColor: root.highColor
        lowColor: root.lowColor
    }

    Component.onCompleted: papa.refresh()
    onVisibleChanged: if (!visible)
                          papa.refresh()
}
