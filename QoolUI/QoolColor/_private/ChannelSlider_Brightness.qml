pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// 明度通道滑块：竖直 ChannelBar + hsvValueF 双向绑定。
//
// 易误解点
// - 与 ColorSlider_Value 同样操作 hsvValueF，但外观不同（白色填充条）；
//   RGBPanel 的"明度"用本件、HSVPanel 的 Value 用 ColorSlider_Value，勿混淆。
// - 标题 "BRIT" 是刻意 4 字母缩写，勿"修正"。
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
