import QtQuick
import QtQuick.Templates as T

import Qool

// Qool.Controls.Components.BasicTextField：Qool 系列文本域单层基底——
// **主题化默认 TextField**（标准行为 + Qool 主题），不掺入行为决策。
// 系列可编辑控件（EditableText 双层版的编辑层、ComboBox/SpinBox 的编辑域）
// 统一消费本类型作为编辑基底；亦可在宿主处作为普通文本域直接使用。
//
// 特化能力：无（相对 Qt 官方 TextField）。Esc 处理不下沉：本类型定位 =
// 主题化默认 TextField，不改变标准行为；Esc 收尾是**行为型**（改变 Esc
// 键默认效果），属上层对"会话结束方式"的控制——由使用方（如 EditableText
// 双层版编辑层）自行处理。editingFinished 信号留给使用方（编辑层实例挂
// 统一收尾——实例 handler 覆盖组件定义，本类型不占用）。

T.TextField {
    id: root

    color: Style.text
    selectionColor: Style.highlight
    selectedTextColor: Style.highlightedText
    verticalAlignment: Text.AlignVCenter

    // 无背景（透明）：双层编辑切换（displayItem ↔ 编辑层）无视觉跳动；
    // 视觉背景由消费方壳层（QoolControl 等）或本类型 background 属性提供
    //（官方 Basic 样式默认背景不适用 Qool 双层编辑场景）
}
