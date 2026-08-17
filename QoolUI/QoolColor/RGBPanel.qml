// 单行竖直通道滑块面板：GridLayout 一行五列——明度
// （ChannelSlider_Brightness，showBrightness 控制，默认隐藏）、
// 红/绿/蓝、透明度（ChannelSlider_Alpha，showAlpha 控制）。
// 交互：各滑块竖直拖动（自下而上 0→1）、双击重置（通道默认值 1）、
//   滑块内嵌数值输入（x>1→/1000+限幅，滑块自身处理）。
// 刻意，勿改：本面板不向滑块传 animationEnabled，滑块各自取 Style.animationEnabled。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

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

    ChannelSlider_Brightness {
        visible: root.showBrightness
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    } //brightnessSlider

    ChannelSlider_Red {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    } //redSlider

    ChannelSlider_Green {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    } //greenSlider

    ChannelSlider_Blue {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    } //blueSlider

    ChannelSlider_Alpha {
        visible: root.showAlpha
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 4
    } //alphaSlider
}
