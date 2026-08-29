import QtQuick
import QtQuick.Controls as Quick
import Qool.Controls.Components
import Qool

Quick.MenuBar {
    id: root

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.menuCutSize
        fillColor: root.Style.controlBackgroundColor
        borderWidth: 1
        borderColor: root.Style.controlBorderColor
    }

    background: QoolBox {
        settings: root.backgroundSettings
        implicitHeight: 5
        implicitWidth: 5
    }

    topPadding: root.backgroundSettings.borderWidth
    bottomPadding: root.backgroundSettings.borderWidth
    leftPadding: (background?.settings?.cutSpaceOnLeft ?? 0) + root.backgroundSettings.borderWidth
    rightPadding: root.backgroundSettings.borderWidth

    delegate: QoolMenuBarItem {}
}
