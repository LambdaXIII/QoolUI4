pragma ComponentBehavior: Bound

import QtQuick
import Qool

/*!
    \qmltype ColorEdit
    \inqmlmodule Qool.Color
    \brief 色名显示 + 点击编辑（v3 ColorEdit 迁移）。

    双态组件：
    \list 1
    \li \b 显示态：显示 \l {ColorDB}{ColorDB.name(currentColor)} 的
        最近色名（文本右对齐）。
    \li \b 编辑态：点击（IBeam 光标）进入；编辑框内容为显示态文本并
        全选，随输入实时解析回写 \l currentColor；回车或失焦结束编辑
        并发出 \l editingFinished。
    \endlist

    \section1 输入解析（易误解，特别说明）

    编辑框内容按"颜色名或 \c #RRGGBB / \c #AARRGGBB 十六进制"经
    \l {ColorDB}{ColorDB.color(text, defaultColor)} 解析：
    \list
    \li 解析失败（含输入中间态，如刚输入 "re" 尚未成 "red"）时
        \c currentColor 被置为 \l defaultColor——\b 输入过程中的瞬时
        回退是 v3 行为照迁，不是 bug。
    \li 本组件是"颜色名输入"，\b 不适用 \l NumInput 的
        \c x > 1 → /1000 数值约定：输入 "350" 会被解析失败回退默认色，
        不是 0.35。
    \endlist

    \section1 编辑往返

    \list
    \li 进入编辑态：\l edit()（点击或程序调用）——文本 = 显示文本、
        全选、显示编辑框、抢焦点。
    \li 结束编辑态：编辑框的
        \l {https://doc.qt.io/qt-6/qml-qtquick-textinput.html#editingfinished-signal}
        {TextInput.editingFinished}（回车或失焦）——隐藏编辑框并发出
        \l editingFinished。\b 失焦结束即视为提交（无"取消"语义，内容
        已解析写回），v3 行为照迁。
    \li 编辑期间 \c currentColor 随输入实时变化（见上"输入解析"），
        显示态文本同时被隐藏。
    \endlist

    \section1 默认值

    \c currentColor 默认等于 \c defaultColor（\c "white"）——默认状态
    自洽，独立使用（不绑定 \l ColorAssistant）成立。

    \section1 属性

    \qmlproperty color ColorEdit::currentColor
    当前颜色。显示态由 \l {ColorDB}{ColorDB.name()} 渲染为色名；编辑态
    由输入文本解析回写（失败回退 \l defaultColor）。

    \qmlproperty color ColorEdit::defaultColor
    默认色，同时是解析失败的回退色，默认 \c "white"。

    \qmlproperty bool ColorEdit::editing
    只读，是否处于编辑态（等于编辑框可见性）。

    \qmlproperty int ColorEdit::horizontalAlignment
    文本水平对齐，默认 \c Text.AlignRight。

    \qmlproperty font ColorEdit::font
    显示与编辑共用字体，默认 \l {PixelFont}{PixelFont.normal}
    （MozartNBP 24px），与 v3 一致。

    \section1 信号

    \qmlsignal ColorEdit::editingFinished()
    编辑结束（回车或失焦）时发出。

    \section1 方法

    \qmlmethod void ColorEdit::edit()
    程序化进入编辑态（与点击等价）。
*/
Item {
    id: root

    property color defaultColor: "white"
    property color currentColor: defaultColor
    readonly property bool editing: editor.visible

    property int horizontalAlignment: Text.AlignRight

    property font font: PixelFont.normal

    signal editingFinished

    implicitHeight: display.implicitHeight
    implicitWidth: display.implicitWidth

    Text {
        id: display
        color: root.Style.text
        font: root.font
        anchors.fill: parent
        horizontalAlignment: root.horizontalAlignment
        Binding {
            when: !editor.visible
            display.text: ColorDB.name(root.currentColor)
            restoreMode: Binding.RestoreNone
        }
    } //display

    MouseArea {
        id: mArea
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: root.edit()
    } //mArea

    // 编辑态：v3 BasicTextInput（Qool.Controls.Basic）内联为 TextInput。
    // 不复用 NumInput 的原因：显示态内容（ColorDB 色名渲染）与编辑内容
    // （原始文本）不同，NumInput 的滚动显示/数值约定（x>1 → /1000）与
    // 本组件的颜色名输入无关——见文件头 QDoc。
    TextInput {
        id: editor
        visible: false
        anchors.fill: parent
        activeFocusOnPress: true
        selectByMouse: true
        wrapMode: TextInput.NoWrap
        color: root.Style.text
        font: root.font
        selectedTextColor: ThemeDB.recommendForeground(root.currentColor)
        selectionColor: root.currentColor
        horizontalAlignment: root.horizontalAlignment
        onEditingFinished: {
            editor.visible = false
            root.editingFinished()
        }
        onTextChanged: {
            root.currentColor = ColorDB.color(text, root.defaultColor)
        }
    } //editor

    function edit() {
        editor.text = display.text
        editor.selectAll()
        editor.visible = true
        editor.forceActiveFocus()
    }
}
