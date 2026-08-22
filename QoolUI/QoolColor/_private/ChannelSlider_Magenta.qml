pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 品红通道滑块：竖直 ChannelBar + magentaF 双向绑定。
// 标题 "MAGT" 是刻意 4 字母缩写，勿"修正"。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "MAGT"
    channelColor: "magenta"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "magentaF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.magentaF
        restoreMode: Binding.RestoreNone
    }
}
