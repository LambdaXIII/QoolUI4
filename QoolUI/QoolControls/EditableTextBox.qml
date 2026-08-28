import QtQuick
import Qool.Controls.Components

ScrollView {
    id: root

    property alias text: textArea.text
    property alias readOnly: textArea.readOnly
    property alias color: textArea.color
    property alias selectionColor: textArea.selectionColor
    property alias selectedTextColor: textArea.selectedTextColor
    property alias wrapMode: textArea.wrapMode
    property alias textFormat: textArea.textFormat
    property alias selectByMouse: textArea.selectByMouse

    // 信号转发（BasicTextArea 预留信号的首个消费方——组件内连接，宿主连 root）
    signal textEdited
    signal editingFinished

    BasicTextArea {
        id: textArea

        selectByMouse: !readOnly

        onTextEdited: root.textEdited()
        onEditingFinished: root.editingFinished()

        Keys.onEscapePressed: focus = false
    }

    implicitWidth: 240
    implicitHeight: 120
}
