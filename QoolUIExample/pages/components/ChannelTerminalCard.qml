import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Chat
import Qool.Controls.Components

BasicButton {
    id: root
    required property ChatRoom chatRoom
    required property string channel      // 角色名==属性名，引擎填充
    required property int index
    readonly property alias logger: messageLogger
    checkable: true

    backgroundSettings.borderColor: checked ? Style.accent : Style.controlBorderColor

    // Beeper 默认属性 apps 挂载 MessageLogger——刻意展示的标准惯用法
    Beeper {
        id: beeper
        chatRoom: root.chatRoom
        channel: root.channel
        apps: MessageLogger {
            id: messageLogger
            maxLength: 500    // 显式放宽（模块默认 50），issue 05 验收项
        }
    }

    // Beeper 不缓存消息：最新消息取 logger 尾元素，计数取 length
    readonly property string latestMessage: messageLogger.length > 0
        ? messageLogger.messages[messageLogger.length - 1].content : ""
    // "__ALL__" 是 MsgChannel::ALL 的符号化结果，显示层还原为 ALL
    readonly property string displayChannel: beeper.channel === "__ALL__"
        ? "ALL" : beeper.channel

    contentItem: ColumnLayout {
        spacing: 4
        Text { text: root.displayChannel; font.pixelSize: Style.controlTitleTextSize; color: Style.text; elide: Text.ElideRight; Layout.fillWidth: true }
        Text { text: root.latestMessage; font.pixelSize: Style.controlTextSize; color: Style.text; elide: Text.ElideRight; Layout.fillWidth: true }
        Text { text: qsTr("记录 %1 条").arg(messageLogger.length); font.pixelSize: Style.controlTextSize; color: Style.text }
    }
    // 不设 enabled 开关：所有 Beeper 常驻工作（issue 05）
}
