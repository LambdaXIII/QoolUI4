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
    required property ListModel channelModel
    title: qsTr("消息发送装置")

    ButtonGroup {
        id: channelGroup
    }

    contentItem: GridLayout {
        columns: 2
        EditableText {
            id: input
            onAccepted: root.send()
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            Text {
                text: qsTr("在这里输入消息")
                font.pixelSize: Style.decorativeTextSize
                color: Style.infoColor
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                visible: input.text === "" && !input.editing
            }
            font.pixelSize: 28
        }

        Button {
            id: sendButton
            text: qsTr("发送")
            onClicked: root.send()
            Layout.fillHeight: true
            Layout.row: 0
            Layout.column: 1
            Layout.rowSpan: 2
        }

        RowLayout {
            Layout.row: 1
            Layout.column: 0
            BasicControlText {
                horizontalAlignment: Text.AlignLeft
                text: qsTr("选择频道：")
                Layout.fillWidth: true
            }
            Flow {
                Repeater {
                    model: root.channelModel
                    delegate: ToolButton {
                        required property string name
                        required property string channel   // 角色名==属性名，引擎填充
                        required property int index
                        required property color channelColor
                        text: name
                        checkable: true
                        checked: index === 0
                        ButtonGroup.group: channelGroup
                        Style.highlight: channelColor
                    }
                }

                Layout.alignment: Qt.AlignRight
            }
        }//toolbar

    }//contentItem

    function send() {
        const btn = channelGroup.checkedButton;
        // editText=judge 常驻编辑模型：编辑中/结束后都是当前真值（见 EditableText.qml 注释块）
        const text = input.editText.trim();
        if (!btn || !text)
            return;
        root.chatRoom.postMessage(btn.channel, {
            content: text
        });
    }
}
