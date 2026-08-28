import QtQuick
import QtQuick.Controls as Quick
import Qool
import Qool.Controls.Components

Quick.Menu {
    id: root

    // 默认：菜单栏顶级/子菜单隐藏标题，独立（上下文）菜单显示——兼容通常 Menu 行为
    property bool showTitle: !(pCtrl.isInMenuBar || pCtrl.isSubMenu)

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.controlBorderColor
        fillColor: root.Style.controlBackgroundColor
        cutSizeTL: root.showTitle ? root.Style.menuCutSize : 0
    }

    QtObject {
        id: pCtrl
        readonly property bool isInMenuBar: root.parent as Quick.MenuBarItem
        readonly property bool isSubMenu: root.parent as Quick.MenuItem
    }

    //Menu默认有一圈很宽的Inset
    topPadding: topInset + bgBox.topSpace
    leftPadding: leftInset + bgBox.leftSpace
    rightPadding: rightInset + bgBox.rightSpace
    bottomPadding: bottomInset + bgBox.bottomSpace

    topInset: pCtrl.isInMenuBar ? 4 : 0
    leftInset: 0
    bottomInset: 0
    rightInset: 0

    background: QoolBGBox {
        id: bgBox
        title: root.showTitle ? root.title : ""
        settings: root.backgroundSettings
        implicitWidth: 200
    }

    delegate: MenuItem {}
}
