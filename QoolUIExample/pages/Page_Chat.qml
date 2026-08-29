import QtQuick
import QtQuick.Controls          // 先：Qt 基础类型
import QtQuick.Layouts
import Qool
import Qool.Chat
import Qool.Controls             // 后：Qool 同名类型（SplitView/Button 等）覆盖 Qt 的
import Qool.Controls.Components
import "components"

BasicPage {
    id: root
    title: qsTr("消息总线")
    note: qsTr("ChatRoom / Beeper / MessageLogger——房间、终端与记录器")
    implicitHeight: cc.implicitHeight

    // 页面级唯一状态源（一）：单房间多频道
    ChatRoom { id: room; name: "DEMO" }
    // 页面级唯一状态源（二）：频道 model 一处定义、chips 与卡组两处消费
    ListModel {
        id: channelModel
        ListElement { channel: "ALL" }
        ListElement { channel: "news" }
        ListElement { channel: "sports" }
        ListElement { channel: "tech" }
        ListElement { channel: "news sports tech" }   // model 被 chips 与卡组共用：此条既是多频道芯片（点击=向三条频道广播）也是多频道订阅卡
    }

    // 终端卡互斥单选组：checkedButton 即「日志看哪台」
    ButtonGroup { id: cardGroup }

    Column {
        id: cc
        width: parent.width
        spacing: 12

        ChatSender {
            width: parent.width
            chatRoom: room
            channels: channelModel
        }

        SplitView {
            width: parent.width
            height: 380
            orientation: Qt.Horizontal

            BasicControl {
                title: qsTr("频道终端")
                SplitView.fillWidth: true
                SplitView.fillHeight: true
                contentItem: RowLayout {
                    spacing: 10
                    Repeater {
                        model: channelModel
                        delegate: ChannelTerminalCard {
                            chatRoom: room
                            checked: index === 0          // 默认选中第一张（ALL）；index 是卡片 required property（引擎按角色填充，非 context 注入）
                            ButtonGroup.group: cardGroup
                            Layout.preferredWidth: 170
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            ChatLogView {
                SplitView.preferredWidth: 420
                SplitView.fillHeight: true
                // 日志数据源 = 选中卡的 logger；选中哪台看哪台
                messages: cardGroup.checkedButton ? cardGroup.checkedButton.logger.messages : null
            }
        }
    }
}
