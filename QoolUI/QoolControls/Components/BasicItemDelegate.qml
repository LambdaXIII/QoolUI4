import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import Qool

T.ItemDelegate {
    id: root

    font.pixelSize: Style.controlTextSize
    font.weight: root.highlighted ? Font.DemiBold : Font.Normal

    contentItem: BasicButtonText {
        text: root.text
        color: root.highlighted ? root.Style.highlight : root.Style.buttonText
        font: root.font
        BasicColorBehavior on color {}
    }

    topPadding: 4
    bottomPadding: 4

    background: Item {
        implicitHeight: 10
        implicitWidth: 10
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
