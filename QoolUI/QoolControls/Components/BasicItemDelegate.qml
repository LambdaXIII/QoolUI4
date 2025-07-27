import QtQuick
import QtQuick.Templates as T
import Qool

T.ItemDelegate {
    id: root

    contentItem: BasicButtonText {
        text: root.text
        color: root.highlighted ? root.Style.highlightedText : root.Style.buttonText
    }

    background: Rectangle {
        color: root.highlighted ? root.Style.highlight :
                                  root.Style.controlBackgroundColor
    }
    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
