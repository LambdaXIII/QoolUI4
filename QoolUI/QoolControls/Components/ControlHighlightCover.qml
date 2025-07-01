import QtQuick
import Qool

CutCornerBox {
    id: root

    property color highColor: palette.highlight
    property color lowColor: palette.highlightedText
    property var words: Qore.style.papaWords

    clip: true

    settings {
        color: root.highColor
        borderColor: "transparent"
        borderWidth: 0
    }

    z: 95
    anchors {
        fill: parent
        topMargin: parent.topInset
        bottomMargin: parent.bottomInset
        leftMargin: parent.leftInset
        rightMargin: parent.rightInset
    }

    Text {
        id: highlightWord
        z: 1
        color: root.lowColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: root.height / 2
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    function updateHighlightWord() {
        highlightWord.anchors.verticalCenterOffset = Math.random(
                    ) * (root.height / 2) - root.height / 4
        highlightWord.anchors.horizontalCenterOffset = Math.random(
                    ) * (root.width / 2) - root.width / 4
        highlightWord.rotation = -45 + Math.random() * 90
        highlightWord.scale = Math.random() + 1
        highlightWord.text = root.words[Math.floor(
                                            Math.random(
                                                ) * Style.papaWords.length)]
    }

    Component.onCompleted: updateHighlightWord()
    onVisibleChanged: if (!visible)
                          updateHighlightWord()
}
