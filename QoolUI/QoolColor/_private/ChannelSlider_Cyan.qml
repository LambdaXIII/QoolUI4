pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 青色通道滑块：竖直 ChannelBar + cyanF 双向绑定
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "CYAN"
    channelColor: "cyan"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "cyanF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.cyanF
        restoreMode: Binding.RestoreNone
    }
}
