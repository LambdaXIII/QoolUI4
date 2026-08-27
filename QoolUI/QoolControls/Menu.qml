import QtQuick
import QtQuick.Controls as Quick
import Qool
import Qool.Controls.Components

Quick.Menu {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    //默认为 false，以兼容通常的Menu行为
    property bool showTitle: !(pCtrl.isInMenuBar || pCtrl.isSubMenu)

    property QoolBoxSettings settings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.controlBorderColor
        fillColor: root.Style.controlBackgroundColor
        cutSizeTL: root.showTitle ? root.Style.menuCutSize : 0
    }

    //不建议设置为Window，checkable的Action将会有一些问题
    // popupType: Quick.Popup.Window

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
        settings: root.settings
        implicitWidth: 200
    }

    delegate: MenuItem {}
}
