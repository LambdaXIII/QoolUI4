pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 黄色通道滑块：竖直 ChannelBar + yellowF 双向绑定。
//
// 易误解点
// - 标题 "YELO" 是刻意 4 字母缩写，勿"修正"。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "YELO"
    channelColor: "yellow"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "yellowF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.yellowF
        restoreMode: Binding.RestoreNone
    }
}
