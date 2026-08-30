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
    ChatRoom {
        id: room
        name: "DEMO"
    }
    // 页面级唯一状态源（二）：频道 model 一处定义、chips 与卡组两处消费
    ListModel {
        id: channelModel
        ListElement {
            channel: "ALL"
            name: "所有频道"
            channelColor: "red"
        }
        ListElement {
            channel: "channel-01"
            name: "洞幺"
            channelColor: "yellow"
        }
        ListElement {
            channel: "channel-02"
            name: "洞拐"
            channelColor: "cyan"
        }
        ListElement {
            channel: "channel-03"
            name: "修仙群"
            channelColor: "lightGreen"
        }
        ListElement {
            channel: "channel-04"
            name: "小区业主"
            channelColor: "pink"
        }
        ListElement {
            channel: "channel-05"
            name: "部门闲聊"
            channelColor: "lightGray"
        }   // model 被 chips 与卡组共用：此条既是多频道芯片（点击=向三条频道广播）也是多频道订阅卡
    }

    GridLayout {
        id: cc
        width: 800
        rowSpacing: 8
        columnSpacing: 8
        columns: 2
        LayoutItemProxy {
            target: sender
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }

        LayoutItemProxy {
            target: terminals
            Layout.fillWidth: true
        }

        LayoutItemProxy {
            target: msgLogView
            Layout.preferredWidth: 420
            Layout.fillHeight: true
        }
    }//cc

    ChatSender {
        id: sender
        width: parent.width
        chatRoom: room
        channelModel: channelModel
    }

    ColumnLayout {
        id: terminals
        spacing: 10
        Repeater {
            model: channelModel
            delegate: ChannelTerminalCard {
                chatRoom: room
                checked: index === 0
                onClicked: msgLogView.messages = logger.messages
                Layout.fillWidth: true
            }
        }
    }

    ChatLogView {
        id: msgLogView
    }
}
