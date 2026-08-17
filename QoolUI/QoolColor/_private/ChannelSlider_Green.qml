// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Green.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.greenF /
// 非交互从 greenF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "green"，标题 "GRIN" 是 v3 的 4 字母缩写（与 RED/BLUE 等
// 同风格，勿当拼写错误"修正"）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 绿色通道滑块（v3 逐字迁移）：竖直 ChannelBar + greenF 双向绑定。
//
// 易误解点
// - 标题 "GRIN" 是 v3 刻意采用的 4 字母缩写（GREEN→GRIN），非拼写错误；
//   整套 ChannelSlider 变体（BRIT/ALFA/MAGT/YELO/BLAK 等）均为此风格。
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
