import QtQuick
import QtQuick.Controls as Quick
import Qool.Controls.Components
import Qool

Quick.MenuBar {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    background: QoolBox {
        settings {
            cutSizeTL: Style.menuCutSize
            fillColor: Style.controlBackgroundColor
            borderWidth: 1
            borderColor: Style.controlBorderColor
        }
        implicitHeight: 5
        implicitWidth: 5
    }

    topPadding: 1
    bottomPadding: 1
    leftPadding: Style.menuCutSize
    rightPadding: 1

    delegate: QoolMenuBarItem {
        animationEnabled: root.animationEnabled
    }
}
