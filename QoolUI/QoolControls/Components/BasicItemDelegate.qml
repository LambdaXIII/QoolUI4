import QtQuick
import QtQuick.Templates as T
import Qool

T.ItemDelegate {
    id: root

    contentItem: BasicButtonText {
        text: root.text
        color: root.highlighted ? root.Style.highlight : root.Style.buttonText
        BasicColorBehavior on color {}
    }

    topPadding: 4
    bottomPadding: 4

    background: Item {
        implicitHeight: 10
        implicitWidth: 10
        Rectangle {
            width: root.highlighted ? parent.width : 0
            BasicNumberBehavior on width {}
            height: 2
            y: parent.height - height
            x: (parent.width - width) / 2
            color: root.Style.highlight
        }
    }

    implicitWidth: {
        let w1 = leftPadding + implicitContentWidth + rightPadding;
        let w2 = leftInset + implicitBackgroundWidth + rightInset;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        let h1 = topPadding + implicitContentHeight + bottomPadding;
        let h2 = topInset + implicitBackgroundHeight + bottomInset;
        return Math.max(h1, h2);
    }
}
