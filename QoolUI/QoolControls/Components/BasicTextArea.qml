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

/*!
    \qmltype BasicTextArea
    \inqmlmodule Qool.Controls.Components
    \inherits TextArea

    \brief Qool 系列文本域多行基底——主题化默认 TextArea（标准行为 +
    Qool 主题），不掺入行为决策。

    BasicTextArea 是 Qt Quick Controls \l TextArea 的主题化版本：行为与
    官方完全一致（Enter 换行、Tab 输入制表符、placeholderText 提示、不自带
    滚动等），仅提供 Qool 主题默认——文本三色、字体、换行模式与对齐。

    与 \l BasicTextField（单行基底）对称：宿主可直接作为多行文本域使用，
    亦可作为未来多行编辑会话（多行双层版）的编辑层基底。

    \section1 接口兼容性

    继承 Qt Quick Controls 的 \l TextArea（其继承 QtQuick 的 TextEdit）——
    官方 API 全部可用（text / placeholderText / readOnly / selectByMouse /
    textFormat / contentHeight / editingFinished() / textEdited() 等），宿主
    可参照官方文档。本类型不改变官方行为，仅设置 Qool 主题默认值，以下
    仅文档化 Qool 设置的部分。

    \section1 Qool 默认值

    \qmlproperty color color
    文本色——默认 Style.text（Qool 主题）。

    \qmlproperty color selectionColor
    选中背景色——默认 Style.highlight（Qool 主题）。

    \qmlproperty color selectedTextColor
    选中文本色——默认 Style.highlightedText（Qool 主题）。

    \qmlproperty font font
    字体——默认 Style.controlTextSize 字号（Qool 主题）。宿主可整体
    覆盖（font 属性照常）。

    \qmlproperty int wrapMode
    换行模式——默认 TextEdit.Wrap（多行文本域惯例；官方默认 NoWrap）。
    文本到达控件宽度自动折行；宿主可改回官方默认或其他模式。

    \qmlproperty int verticalAlignment
    垂直对齐——默认 TextEdit.AlignTop（官方 TextEdit 默认值，显式声明
    以对齐 BasicTextField 的显式化惯例——单行 AlignVCenter / 多行
    AlignTop）。

    \section1 行为说明

    \list
    \li \b 无背景（透明）：视觉背景由使用方（壳层/布局背景）提供，或经
        background 属性设置——与 BasicTextField 同约定（官方 Basic 样式
        默认背景不适用于 Qool 分层场景）。
    \li \b Esc 不下沉：本类型不改变官方行为（Esc 不结束编辑）；编辑会话
        的结束方式（如 Esc 收尾）属上层"会话结束方式"控制。
    \li \b editingFinished / textEdited 信号留给使用方：本类型不占用（实例
        handler 覆盖组件定义——未来编辑层消费方挂统一收尾不被覆盖）。
    \li \b 不自带滚动：官方 TextArea 行为（TextEdit 无滚动）——需要滚动时
        由宿主置于 ScrollView/Flickable 中组合（TextArea.flickable 附加
        属性可用）。
    \li \b placeholderText / placeholderTextColor：官方属性，直接可用。
    \endlist
*/

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
