import QtQuick
import Qool

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
            display.text: ColorNameHQ.name(root.currentColor)
            restoreMode: Binding.RestoreNone
        }
    } //display

    MouseArea {
        id: mArea
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: root.edit()
    } //mArea

    // 编辑态：BasicTextInput 内联为 TextInput。
    // 不复用 NumInput 的原因：显示态内容（ColorNameHQ 色名渲染）与编辑内容
    // （原始文本）不同，NumInput 的滚动显示/数值约定（x>1 → /1000）与
    // 本组件的颜色名输入无关——见文件头文档。
    TextInput {
        id: editor
        visible: false
        anchors.fill: parent
        activeFocusOnPress: true
        selectByMouse: true
        wrapMode: TextInput.NoWrap
        color: root.Style.text
        font: root.font
        selectedTextColor: ThemeHQ.recommendForeground(root.currentColor)
        selectionColor: root.currentColor
        horizontalAlignment: root.horizontalAlignment
        onEditingFinished: {
            // 失焦/回车结束即视为提交（无"取消"语义——内容已解析写回）。
            editor.visible = false;
            root.editingFinished();
        }
        onTextChanged: {
            // 解析失败（含输入中间态，如刚输入 "re" 尚未成 "red"）时
            // currentColor 回退 defaultColor——瞬时回退非 bug。
            root.currentColor = ColorNameHQ.color(text, root.defaultColor);
        }
    } //editor

    function edit() {
        editor.text = display.text;
        editor.selectAll();
        editor.visible = true;
        editor.forceActiveFocus();
    }
}
