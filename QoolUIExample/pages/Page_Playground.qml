// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前用途：ChannelControl 双形态呈现检查——水平（编辑行上 +
// ChannelCrystalSlider 下）与竖直（ChannelBoxSlider 上 +
// tagOnTop 编辑行下），两实例绑定同一共享 ColorAssistant。
import QtQuick
import QtQuick.Controls
import Qool
import Qool.Controls as Q

import Qool.Color
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("ChannelControl 双形态：水平 / 竖直，共享同一 Assistant")

    Q.QoolButton {
        id: button
        text: "CLICK ME!!"
        ContextMenu.menu: menu
    }

    Q.Menu {
        id: menu
        title: "毁天灭地"
        showTitle: ii.checked
        Action {
            text: "AAA"
            enabled: false
        }
        Action {
            text: "AAA"
        }
        Action {
            text: "AAA"
        }
        Action {
            text: "AAA"
        }
        Action {
            text: "AAA"
        }
        Action {
            id: ii
            text: "AAA"
            checkable: true
        }

        Q.Menu {
            title: "SUB"
            Action {
                text: "AAA"
                enabled: false
            }
            Action {
                text: "AAA"
            }
            Action {
                text: "AAA"
            }
            Action {
                text: "AAA"
            }
            Action {
                text: "AAA"
            }
            Action {
                text: "AAA"
                checkable: true
            }
        }
    }
}//page
