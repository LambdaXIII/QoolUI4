pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 红色通道滑块：竖直 ChannelBar + redF 双向绑定
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "RED"
    channelColor: "red"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "redF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.redF
        restoreMode: Binding.RestoreNone
    }
}
