// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Brightness.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.hsvValueF /
// 非交互从 hsvValueF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "white"（明度滑块用白色填充，v3 原样——注意与 Value 滑块
// 的语义区别：本件是 RGBPanel 里的"明度"通道，仍走 hsvValueF）。
// 标题 "BRIT" 是 v3 的 4 字母缩写（BRIGHTNESS→BRIT）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 明度通道滑块（v3 逐字迁移）：竖直 ChannelBar + hsvValueF 双向绑定。
//
// 易误解点
// - 与 ColorSlider_Value 同样操作 hsvValueF，但外观不同（白色填充条）；
//   RGBPanel 的"明度"用本件、HSVPanel 的 Value 用 ColorSlider_Value，勿混淆。
// - 标题 "BRIT" 是 v3 刻意 4 字母缩写，勿"修正"。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "BRIT"
    channelColor: "white"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "hsvValueF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.hsvValueF
        restoreMode: Binding.RestoreNone
    }
}
