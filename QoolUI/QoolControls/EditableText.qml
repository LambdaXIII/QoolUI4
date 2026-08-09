import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool.Controls as Q
import Qool

// Qool.Controls.EditableText：可编辑控件的内容组件（display/editor 双层 +
// 编辑状态机 + 信号契约）。供 SpinBox/ComboBox 等作默认 contentItem。
// 骨架版：细节（样式/替换面/输入提示）待大体逻辑确认后补充。

T.Control {
    id: root

    property string displayText
    property string editText: root.displayText
    property bool editable: true
    readonly property bool editing: pCtrl.editing
    property var validator

    signal editingStarted()
    signal editingFinished(string text)
    signal rejected()

    QtObject {
        id: pCtrl
        property bool editing: false
        function start_edit() {
            if (pCtrl.editing || !root.editable)
                return
            pCtrl.editing = true
            let ed = editorLoader.item
            if (!ed)
                return
            ed.text = root.editText
            ed.selectAll()
            ed.forceActiveFocus()
            root.editingStarted()
        }
        function end_edit() {
            if (!pCtrl.editing)
                return
            pCtrl.editing = false
            let ed = editorLoader.item
            if (ed)
                ed.focus = false
        }
    }

    contentItem: Item {
        implicitWidth: displayItem.implicitWidth
        implicitHeight: displayItem.implicitHeight

        Text {
            id: displayItem
            text: root.displayText
            visible: !pCtrl.editing
            anchors.fill: parent
        }

        Loader {
            id: editorLoader
            anchors.fill: parent
            active: pCtrl.editing
            sourceComponent: Q.TextField {
                id: editor
                text: root.editText
                validator: root.validator
                font: root.font
                onAccepted: {
                    root.editingFinished(text)
                    pCtrl.end_edit()
                }
                onActiveFocusChanged: if (!activeFocus && pCtrl.editing) {
                    root.editingFinished(text)
                    pCtrl.end_edit()
                }
                onRejected: root.rejected()
            }
        }

        TapHandler {
            enabled: root.editable && !pCtrl.editing
            onTapped: pCtrl.start_edit()
        }
    }

    function start_edit() { pCtrl.start_edit() }
}
