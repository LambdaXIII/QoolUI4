import QtQuick
import Qool

Item {
    id: root

    property color highColor: palette.highlight
    property color lowColor: palette.highlightedText

    property list<string> words: Qore.style.papaWords
    property font font
    font.pixelSize: height / 2
    font.bold: true

    Rectangle {
        anchors.fill: parent
        color: root.highColor
    }

    Text {
        id: highWord
        z: 1
        color: root.lowColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        font: root.font
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    function refresh() {
        highWord.anchors.verticalCenterOffset = Math.random(
                    ) * (root.height / 2) - root.height / 4
        highWord.anchors.horizontalCenterOffset = Math.random(
                    ) * (root.width / 2) - root.width / 4
        highWord.rotation = -45 * (Math.random() * 90)
        highWord.scale = Math.random() + 1
        const word_index = Math.floor(Math.random() * root.words.length)
        highWord.text = root.words[word_index]
    }
}
