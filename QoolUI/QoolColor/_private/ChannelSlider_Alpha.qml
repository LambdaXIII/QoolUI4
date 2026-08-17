pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 透明度通道滑块：竖直 ChannelBar + alphaF 双向绑定。
//
// 易误解点
// - 与 ColorSlider_Alpha 同样操作 alphaF；本件是 CMYK 面板的透明度通道
//   （channelColor 灰色），勿与 HSV 面板的 ALPHA 滑块（渐变轨道）混淆。
// - 标题 "ALFA" 是刻意 4 字母缩写，勿"修正"。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "ALFA"
    channelColor: "grey"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "alphaF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.alphaF
        restoreMode: Binding.RestoreNone
    }
}
