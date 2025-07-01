import QtQuick
import Qool
import Qool.Controls.Components

BasicButtonFrame {
    id: root

    property bool flat: false
    property bool highlighted: false

    property color highlightColor: palette.highlight
    property color highlightedTextColor: palette.highlightedText

    hoverEnabled: true

    font.pixelSize: Qore.style.controlTextSize

    contentItem: BasicButtonText {
        text: root.text
        font: root.font
        //TODO:support QtQuick icon behaviors
    }

    ControlPressedCover {
        visible: root.down
        highColor: root.highlightColor
        lowColor: root.highlightedTextColor
        z: 99
    }

    // ControlHighlightCover {
    //     z: 30
    // }
}
