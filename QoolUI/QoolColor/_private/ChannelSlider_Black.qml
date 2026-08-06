// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider_Black.qml 逐字迁移。
// 变体模式：两个互斥 Binding（userInteracting 写 colorAssistant.blackF /
// 非交互从 blackF 同步 root.value，restoreMode: RestoreNone），
// channelColor: "darkgrey"（黑色通道用深灰填充——纯黑填充在黑底主题上
// 不可见，v3 刻意选择，勿改为 "black"）。
// 标题 "BLAK" 是 v3 的 4 字母缩写（BLACK→BLAK）。
// 与 v3 的刻意差异：无（仅注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

/*!
    \qmltype ChannelSlider_Black
    \inqmlmodule Qool.Color
    \brief 黑色通道滑块（v3 逐字迁移）：竖直 ChannelBar + blackF 双向绑定。

    \section2 易误解点
    \list
    \li \c channelColor 是 "darkgrey" 而非 "black"——深色主题下纯黑填充不可见，
        v3 刻意选择深灰，勿"修正"。
    \li 标题 "BLAK" 是 v3 刻意 4 字母缩写，勿"修正"。
    \endlist
*/
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
