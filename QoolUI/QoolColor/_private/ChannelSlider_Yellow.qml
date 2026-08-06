// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Yellow.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.yellowF /
// 非交互从 yellowF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "yellow"。
// 标题 "YELO" 是 v3 的 4 字母缩写（YELLOW→YELO）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

/*!
    \qmltype ChannelSlider_Yellow
    \inqmlmodule Qool.Color
    \brief 黄色通道滑块（v3 逐字迁移）：竖直 ChannelBar + yellowF 双向绑定。

    \section2 易误解点
    \list
    \li 标题 "YELO" 是 v3 刻意 4 字母缩写，勿"修正"。
    \endlist
*/
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "YELO"
    channelColor: "yellow"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "yellowF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.yellowF
        restoreMode: Binding.RestoreNone
    }
}
