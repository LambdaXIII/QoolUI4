pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 绿色通道滑块：竖直 ChannelBar + greenF 双向绑定。
// 标题 "GRIN" 是刻意 4 字母缩写（GREEN→GRIN），非拼写错误——整套变体
// （BRIT/ALFA/MAGT/YELO/BLAK 等）均为此风格。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "GRIN"
    channelColor: "green"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "greenF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.greenF
        restoreMode: Binding.RestoreNone
    }
}
