// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Magenta.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.magentaF /
// 非交互从 magentaF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "magenta"。
// 标题 "MAGT" 是 v3 的 4 字母缩写（MAGENTA→MAGT）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

/*!
    \qmltype ChannelSlider_Magenta
    \inqmlmodule Qool.Color
    \brief 品红通道滑块（v3 逐字迁移）：竖直 ChannelBar + magentaF 双向绑定。

    \section2 易误解点
    \list
    \li 标题 "MAGT" 是 v3 刻意 4 字母缩写，勿"修正"。
    \endlist
*/
ChannelSlider {
    id: root

    property ColorAssistant colorAssistant: ColorAssistant {}

    title: "MAGT"
    channelColor: "magenta"

    Binding {
        when: userInteracting
        target: root.colorAssistant
        property: "magentaF"
        value: root.value
        restoreMode: Binding.RestoreNone
    }

    Binding {
        when: !userInteracting
        target: root
        property: "value"
        value: root.colorAssistant.magentaF
        restoreMode: Binding.RestoreNone
    }
}
