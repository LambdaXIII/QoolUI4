pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 蓝色通道滑块：竖直 ChannelBar + blueF 双向绑定
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "BLUE"
    channelColor: "blue"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "blueF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.blueF
        restoreMode: Binding.RestoreNone
    }
}
