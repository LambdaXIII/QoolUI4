// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Alpha.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.alphaF /
// 非交互从 alphaF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "grey"（透明度通道用灰色填充，v3 原样）。
// 标题 "ALFA" 是 v3 的 4 字母缩写（ALPHA→ALFA）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 透明度通道滑块（v3 逐字迁移）：竖直 ChannelBar + alphaF 双向绑定。
//
// 易误解点
// - 与 ColorSlider_Alpha 同样操作 alphaF；本件是 CMYK 面板的透明度通道
//   （channelColor 灰色），勿与 HSV 面板的 ALPHA 滑块（渐变轨道）混淆。
// - 标题 "ALFA" 是 v3 刻意 4 字母缩写，勿"修正"。
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "ALFA"
    channelColor: "grey"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "alphaF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.alphaF
        restoreMode: Binding.RestoreNone
    }
}
