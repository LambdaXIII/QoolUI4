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
            // 失焦/回车即提交（无取消语义——色值已由 onTextChanged 实时写回）。
            editor.visible = false;
            root.editingFinished();
        }
        onTextChanged: {
            // 解析失败（含输入中间态）回退 defaultColor——瞬时回退非 bug。
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
