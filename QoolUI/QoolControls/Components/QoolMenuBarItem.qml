import QtQuick
import QtQuick.Controls as Quick
import Qool

Quick.MenuBarItem {
    id: root

    font.pixelSize: Style.controlTextSize

    QtObject {
        id: pCtrl
        property color textColor: {
            if (!root.enabled)
                return root.Style.negative;
            if (root.highlighted)
                return root.Style.highlight;
            return root.Style.buttonText;
        }

        BasicColorBehavior on textColor {
            enabled: root.Style.animationEnabled
            easing.type: Easing.InOutQuart
        }
    }

    topPadding: 2
    bottomPadding: 2
    leftInset: 2
    rightInset: 2
    leftPadding: 2
    rightPadding: 2

    contentItem: BasicButtonText {
        text: root.text
        font: root.font
        color: pCtrl.textColor
        elide: Text.ElideRight
    }

    background: HorizontalBar {

        implicitHeight: 10
        implicitWidth: 10
        percentage: root.highlighted ? 1 : 0

        foreground: Item {
            Rectangle {
                border.width: 0
                color: pCtrl.textColor
                width: parent.width
                height: 2
                y: parent.height - height
            }
        }//foreground

        BasicNumberBehavior on percentage {
            enabled: root.Style.animationEnabled
        }
    }//background
}
