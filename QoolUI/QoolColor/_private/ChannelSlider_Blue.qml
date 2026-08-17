// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Blue.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.blueF /
// 非交互从 blueF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "blue"。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 蓝色通道滑块（v3 逐字迁移）：竖直 ChannelBar + blueF 双向绑定。
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
