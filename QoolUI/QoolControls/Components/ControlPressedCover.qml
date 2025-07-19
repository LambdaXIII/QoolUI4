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

    z: 90
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
            borderColor: root.lowColor
            curved: root.settings.curved
        }
        fillItem: papa
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
