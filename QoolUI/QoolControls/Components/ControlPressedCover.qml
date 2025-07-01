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

    z: 90
    anchors {
        fill: parent
        topMargin: parent.topInset
        bottomMargin: parent.bottomInset
        leftMargin: parent.leftInset
        rightMargin: parent.rightInset
    }

    fillItem: papa
    PaPaWall {
        id: papa
        anchors.fill: parent
        visible: false
        layer.enabled: true
    }

    Component.onCompleted: papa.refresh()
    onVisibleChanged: if (!visible)
                          papa.refresh()
}
