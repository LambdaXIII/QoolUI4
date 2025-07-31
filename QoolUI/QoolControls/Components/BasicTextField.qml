import QtQuick
import QtQuick.Templates as T

import Qool

T.TextField {
    id: root

    color: Style.text
    selectionColor: Style.highlight
    selectedTextColor: Style.highlightedText
    verticalAlignment: Text.AlignVCenter

    // background: Rectangle {
    //     border.width: 1
    //     border.color: root.Style.mid
    //     color: root.Style.base
    //     opacity: root.activeFocus ? 1 : 0
    // }
}
