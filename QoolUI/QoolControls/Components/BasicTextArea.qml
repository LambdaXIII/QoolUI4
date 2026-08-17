import QtQuick
import QtQuick.Controls as QC

import Qool

// Qool.Controls.Components.BasicTextArea：Qool 系列文本域多行基底——
// **主题化默认 TextArea**（标准行为 + Qool 主题），不掺入行为决策。
// 与 BasicTextField（单行基底）对称；宿主可直接作为多行文本域使用，
// 亦可作为未来多行编辑会话（多行双层版）的编辑层基底。
//
// 基类用 QC.TextArea（QtQuick.Controls，非 T.TextArea）：T 版在
// ScrollView/Flickable 中无滚动能力（内容尺寸不接驳——2026-08-11 实测
// 裁定）；QC 版置于 ScrollView 时官方集成自动生效（内容尺寸自动/背景不滚/
// clip 自动）。
//
// 特化能力：无（相对 Qt 官方 TextArea）。Esc 处理不下沉：本类型定位 =
// 主题化默认 TextArea，不改变标准行为；Esc 收尾是**行为型**（改变 Esc
// 键默认效果），属上层对"会话结束方式"的控制——由使用方（如未来多行
// 双层版的编辑层）自行处理。editingFinished / textEdited 信号留给使用方
// （编辑层实例挂统一收尾——实例 handler 覆盖组件定义，本类型不占用）。

QC.TextArea {
    id: root

    // 文本三色（Qool 主题——与 BasicTextField 同款）
    color: Style.text
    selectionColor: Style.highlight
    selectedTextColor: Style.highlightedText

    // 字号（Qool 控件惯例——宿主可覆盖 font）
    font.pixelSize: Style.controlTextSize

    // 无背景（透明）：QC.TextArea 有 Basic 样式默认背景（灰底——实测
    // #787878），与本类型透明契约矛盾——显式压掉；视觉背景由消费方壳层
    // 或本类型 background 属性提供（与 BasicTextField 同约定）
    background: null

    // 多行文本域惯例：折行 + 顶部对齐（官方默认 NoWrap / AlignTop——
    // wrapMode 显式开启，AlignTop 显式声明意图）
    wrapMode: TextEdit.Wrap
    verticalAlignment: Text.AlignTop
}
