// NOTE(迁移) v3 Qool.Color/CMYKPanel.qml 迁移。
// 组合模式照迁：单行竖直通道滑块（GridLayout 一行四列）——
// 青/品红/黄/黑（ChannelSlider_Cyan/Magenta/Yellow/Black）。
// 替换点：Style.highlightColor → Style.highlight（见 T08/T10 style_mapping）。
// 交互照迁：各滑块竖直拖动（自下而上 0→1）、双击重置（通道默认值 1）、
//   滑块内嵌数值输入（x>1→/1000+限幅，滑块自身处理）。
// 与 v3 的刻意差异：无（v3 CMYKPanel 本就不向滑块传 animationEnabled，
//   滑块各自取 Style.animationEnabled——v3 原样保留）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

GridLayout {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style）。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ChannelSlider_Cyan {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    } //cyanSlider

    ChannelSlider_Magenta {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    } //magentaSlider

    ChannelSlider_Yellow {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    } //yellowSlider

    ChannelSlider_Black {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    } //blackSlider
}
