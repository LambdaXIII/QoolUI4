pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 透明度通道滑块：竖直 ChannelBar + alphaF 双向绑定。
// 标题 "ALFA" 是刻意 4 字母缩写，勿"修正"。
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
