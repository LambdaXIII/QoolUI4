import QtQuick
import QtQuick.Layouts
import Qool
import Qool.Chat
import Qool.Controls
import Qool.Controls.Components

QoolButton {
    id: root
    required property ChatRoom chatRoom
    required property string channel
    required property int index
    required property string name
    required property color channelColor
    readonly property alias logger: messageLogger

    title: name
    Style.highlight: channelColor
    Style.papaWords: [name]

    // Beeper 默认属性 apps 挂载 MessageLogger——刻意展示的标准惯用法
    Beeper {
        id: beeper
        chatRoom: root.chatRoom
        channel: root.channel
        MessageLogger {
            id: messageLogger
            maxLength: 500    // 显式放宽（模块默认 50），issue 05 验收项
        }
        onMessageRecieved: msg => msgText.text = msg.content
    }

    contentItem: BasicControlText {
        id: msgText
        color: root.channelColor
        font.pixelSize: 28
        padding: 8
        BasicTextBehavior on text {}
        BasicDecorativeText {
            text: qsTr("消息计数:%1条").arg(messageLogger.length)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        HorizontalBar {
            id: box
            anchors.fill: parent
            color: root.channelColor
            alignment: Qt.AlignRight
            percentage: 0
            opacity: 0
            z: -1
        }
        onTextChanged: boxAni.start()
    }//contentItem

    SequentialAnimation {
        id: boxAni
        alwaysRunToEnd: true
        ParallelAnimation {
            NumberAnimation {
                target: box
                property: "percentage"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.InOutCubic
            }
            SequentialAnimation {
                NumberAnimation {
                    target: box
                    property: "opacity"
                    from: 0
                    to: .5
                    duration: 100
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: box
                    property: "opacity"
                    to: 0
                    duration: 300
                    easing.type: Easing.OutQuad
                }
            }
        }
        PropertyAction {
            target: box
            property: "percentage"
            value: 0
        }
    }//boxAni
}
