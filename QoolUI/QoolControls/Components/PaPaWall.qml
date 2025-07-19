import QtQuick
import Qool

Item {
    id: root

    property color highColor: Style.highlight
    property color lowColor: Style.highlightedText

    property list<string> words: Style.papaWords
    property font font
    property alias text: highWord.text

    font.bold: true
    font.pixelSize: Math.round(Math.min(width, height) / 2)

    enum TextSizeMode {
        LargerTextSize,
        SmallerTextSize,
        DependsOnFontSize
    }

    property int textSizeMode: PaPaWall.DependsOnFontSize

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
        const word_index = Math.floor(Math.random() * root.words.length)
        highWord.text = root.words[word_index]

        if (!highWord.text)
            return

        const v_offset = root.height * 0.75 * (Math.random() - 0.5)
        const h_offset = root.width * 0.75 * (Math.random() - 0.5)
        highWord.anchors.verticalCenterOffset = v_offset
        highWord.anchors.horizontalCenterOffset = h_offset

        let words_factor = 1
        if (root.textSizeMode === PaPaWall.RespectFontSize) {
            words_factor = Math.random() + 1
        } else {
            let ref_edge = root.textSizeMode
                === PaPaWall.LargetTextSize ? Math.max(root.width,
                                                       root.height) : Math.min(
                                                  root.width, root.height)
            const words_w = highWord.implicitWidth
            const words_rand_w = ref_edge * (Math.random() + 0.8)
            words_factor = words_rand_w / words_w
        }
        highWord.scale = words_factor

        highWord.rotation = (Math.random() * 90) - 45
    }
}
