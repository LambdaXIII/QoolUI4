// 单行竖直通道控制面板：GridLayout 一行五列——明度
// （ColorChannelControl 竖直形态，showBrightness 控制，默认隐藏）、
// 红/绿/蓝、透明度（showAlpha 控制）。
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
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property bool showAlpha: true
    property bool showBrightness: false

    // 默认状态自洽：默认实例自带默认色，独立使用成立。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ColorChannelControl {
        visible: root.showBrightness
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.HSVValue
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    } //brightness

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Red
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    } //red

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Green
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    } //green

    ColorChannelControl {
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Blue
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    } //blue

    ColorChannelControl {
        visible: root.showAlpha
        colorAssistant: root.colorAssistant
        channel: ColorNameHQ.Alpha
        orientation: Qt.Vertical
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 4
    } //alpha
}
