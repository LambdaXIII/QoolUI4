pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 黑色通道滑块：竖直 ChannelBar + blackF 双向绑定。
// channelColor 是 "darkgrey" 而非 "black"——深色主题下纯黑填充不可见，
// 刻意选择深灰，勿"修正"；标题 "BLAK" 是刻意 4 字母缩写。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "BLAK"
    channelColor: "darkgrey"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "blackF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.blackF
        restoreMode: Binding.RestoreNone
    }
}
