// Playground：测试场——Qool.Controls 控件的调试用例（仓库开发模式：
// 可随意更改，不保留旧内容）。
//
// 当前用途：ColorChannelControl 双形态呈现检查——水平（编辑行上 +
// ColorChannelSlider 下）与竖直（ColorChannelVerticalSlider 上 +
// tagOnTop 编辑行下），两实例绑定同一共享 ColorAssistant。
import QtQuick
import Qool
import Qool.Controls

import Qool.Color
import Qool.Debug

BasicPage {
    id: root

    title: qsTr("测试场")
    note: qsTr("ColorChannelControl 双形态：水平 / 竖直，共享同一 Assistant")

    // 共享色源：本页唯一 Assistant
    ColorAssistant {
        id: mainColor
        color: Style.accent
        // onColorChanged: console.log("current color", color)
    }

    ColorPreviewer {
        colorAssistant: mainColor
    }

    ColorQuickPicker {
        y: 100
    }

    BasicControl {
        x: 400
        y: 600
        RectResizer {}
        contentItem: ColorNameListView {
            clip: true
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    BasicControl {
        x: 20
        RectResizer {}
        contentItem: HSVPanel {
            colorAssistant: mainColor
        }
    }

    BasicControl {
        x: 20
        RectResizer {}
        contentItem: ColorBankPanel {
        }
    }

    // BasicControl {
    //     y: 400
    //     RectResizer {}
    //     contentItem: Row {
    //         Repeater {
    //             model: ColorHQ.channels
    //             delegate: Loader {
    //                 asynchronous: true
    //                 sourceComponent: ColorChannelControl {
    //                     channel: modelData
    //                     colorAssistant: mainColor
    //                     orientation: Qt.Vertical
    //                 }
    //             }
    //         }
    //     }
    // }//sliders

    // BasicControl {
    //     x: 600
    //     RectResizer {}
    //     contentItem: Column {
    //         Repeater {
    //             model: ColorHQ.channels
    //             delegate: Loader {
    //                 asynchronous: true
    //                 sourceComponent: ColorChannelControl {
    //                     channel: modelData
    //                     colorAssistant: mainColor
    //                 }
    //             }
    //         }
    //     }
    // }//sliders
}//page
