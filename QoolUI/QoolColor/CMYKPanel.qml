// 单行竖直通道控制面板：GridLayout 一行四列——青/品红/黄/黑
// （ColorChannelControl 竖直形态）。
// 交互：各列竖直滑块拖动（自下而上 0→1）+ 数值编辑 + 改值边框高亮
//   （ColorChannelControl 内化，见各组件文档）。
// 刻意，勿改：本面板不向子控件传 animationEnabled，子控件各自经
//   parent 链取本面板属性回退 Style.animationEnabled。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Color

GridLayout {
    id: root

    // 动画总开关：父级属性 → Style 传播。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 默认状态自洽：默认实例自带默认色，独立使用成立。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Cyan
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    } //cyan

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Magenta
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    } //magenta

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Yellow
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    } //yellow

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Black
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    } //black
}
