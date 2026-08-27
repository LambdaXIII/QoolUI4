import QtQuick
import QtQuick.Controls as Quick
import QtQuick.Shapes
import Qool
import Qool.Controls.Components

Quick.MenuItem {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    font.pixelSize: Style.controlTextSize - 2

    arrow: HalfCrystal {
        width: height
        height: contentItem.implicitHeight - 4
        anchors.verticalCenter: contentItem.verticalCenter
        anchors.right: contentItem.right
        direction: Qore.E
        borderWidth: 0
        color: pCtrl.fgColor
        visible: root.subMenu
    }

    indicator: Item {
        implicitHeight: contentItem.implicitHeight
        implicitWidth: implicitHeight + 4
        anchors.verticalCenter: contentItem.verticalCenter
        anchors.left: contentItem.left
        visible: root.checkable
        RadioIndicator {
            height: parent.height - 2
            width: height
            y: (parent.height - height) / 2
            color: root.checked ? root.Style.highlight : "transparent"
            borderColor: root.checked ? root.Style.highlight : pCtrl.fgColor
        }
    }

    contentItem: BasicButtonText {
        text: root.text
        font: root.font
        color: pCtrl.fgColor
        horizontalAlignment: Text.AlignLeft
        leftPadding: root.textPadding
        rightPadding: root.arrow.visible ? root.arrow.width : 0
    }

    background: HorizontalBar {
        implicitHeight: 10
        implicitWidth: 10
        alignment: Qt.AlignLeft
        percentage: root.highlighted ? 1 : 0

        foreground: Rectangle {
            border.width: 0
            color: Qt.alpha(root.Style.accent, 0.1)
            Rectangle {
                border.width: 0
                color: Qt.alpha(root.Style.accent, 0.4)
                width: parent.width
                height: 2
                y: parent.height - height
            }
        }//foreground

        BasicNumberBehavior on percentage {
            enabled: root.animationEnabled
        }
    }//background

    QtObject {
        id: pCtrl
        property color fgColor: {
            if (!root.enabled)
                return root.Style.negative;
            if (root.highlighted)
                return root.Style.accent;
            return root.Style.buttonText;
        }
    }

    ControlPressedCover {
        visible: root.down
    }

    ControlLockedCover {}
}
