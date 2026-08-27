import QtQuick
import QtQuick.Controls as Quick
import Qool
import Qool.Controls

import "components"

BasicPage {
    id: root

    title: qsTr("酷酷的菜单")
    note: qsTr("QoolUI.Controls 提供了统一风格的菜单组件系列；比 QtQuick 更多！")

    implicitHeight: parent.implicitHeight

    Quick.Page {
        anchors.fill: parent

        background: Item {}

        header: MenuBar {
            Menu {
                title: qsTr("酷酷的菜单")

                Quick.Action {
                    text: qsTr("我想变酷")
                    checkable: true
                }
                Quick.Action {
                    text: qsTr("我想变不酷")
                    checkable: true
                }

                MenuSeparator {
                    text: qsTr("酷酷的分割线")
                }
                Quick.Action {
                    text: qsTr("我想变不酷")
                }
                Quick.Action {
                    text: qsTr("我想变不酷")
                }
            }
            Menu {
                title: qsTr("美美的菜单")

                MenuBanner {
                    text: qsTr("垂死病中惊坐起\n笑问客从何处来")
                }

                Quick.Action {
                    text: qsTr("我想变美")
                    checkable: true
                }
                Quick.Action {
                    text: qsTr("我不想变美")
                    checkable: true
                }
            }
            Menu {
                title: qsTr("空空的菜单")
                Quick.Action {
                    enabled: false
                    text: qsTr("白日依山尽")
                }
                Quick.Action {
                    enabled: false
                    text: qsTr("黄河入海流")
                }
                Quick.Action {
                    enabled: false
                    text: qsTr("举头望明月")
                }
                Quick.Action {
                    enabled: false
                    text: qsTr("低头思故乡")
                }
            }
        }//menuBar

        QoolBox {
            id: box
            width: 150
            height: 150

            x: 300
            y: 300
            Quick.ContextMenu.menu: Menu {
                title: qsTr("The Box的菜单")
                Quick.Action {
                    text: qsTr("切角")
                    checkable: true
                    onTriggered: box.settings.cutSizeTL = checked ? 35 : 0
                }

                Quick.Action {
                    text: qsTr("变大")
                    onTriggered: {
                        box.width += 10;
                        box.height += 10;
                    }
                }
                Quick.Action {
                    text: qsTr("变小")
                    onTriggered: {
                        box.width -= 10;
                        box.height -= 10;
                    }
                }
            }
        }//box
    }
}
