// 红色通道变体：两个互斥 Binding（userInteracting 写 colorAssistant.redF /
// 非交互从 redF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "red"，标题 4 字母缩写（勿改拼写）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 红色通道滑块：竖直 ChannelBar + redF 双向绑定。
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
