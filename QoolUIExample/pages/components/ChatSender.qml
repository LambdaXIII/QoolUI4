import QtQml.Models   // ListModel 类型
import QtQuick
import QtQuick.Controls          // ButtonGroup
import QtQuick.Layouts
import Qool.Chat
import Qool.Controls
import Qool.Controls.Components

BasicControl {
    id: root
    required property ChatRoom chatRoom
    required property ListModel channels
    title: qsTr("发送装置")

    ButtonGroup { id: channelGroup }

    contentItem: RowLayout {
        spacing: 8
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            EditableText {
                id: input
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft   // 覆盖控件默认 AlignRight
                // 提示：EditableText 是点击进入编辑的会话控件；Enter 提交
                onAccepted: root.send()
            }
            Flow {
                spacing: 6
                Repeater {
                    model: root.channels
                    delegate: Button {
                        required property string channel   // 角色名==属性名，引擎填充
                        required property int index
                        text: channel
                        checkable: true
                        checked: index === 0
                        ButtonGroup.group: channelGroup
                    }
                }
            }
        }
        Button {
            id: sendButton
            text: qsTr("发送")
            Layout.fillHeight: true
            onClicked: root.send()
        }
    }

    function send() {
        const btn = channelGroup.checkedButton
        // editText=judge 常驻编辑模型：编辑中/结束后都是当前真值（见 EditableText.qml 注释块）
        const text = input.editText.trim()
        if (!btn || !text)
            return
        root.chatRoom.postMessage(btn.channel, { content: text })
    }
}
