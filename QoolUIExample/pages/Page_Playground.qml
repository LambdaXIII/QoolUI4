import QtQuick
import Qool
import QtQuick.Shapes
import Qool.Controls.Components
import Qool.Controls
import Qool.Chat

BasicPage {
    id: root

    title: qsTr("试炼场")
    note: qsTr("测试一些东西……")

    property qoolmessage m: "Greetings!"

    ChatRoom {
        id: room
        // name: "BABY"
    }

    Beeper {
        id: beeper
        chatRoom: room
        channel: "greeting"
        onMessageRecieved: msg => {
                               console.log(msg.content)
                           }
    }

    Beeper {
        id: beeper2
        chatRoom: room
        channel: "greeting"
        onMessageRecieved: msg => {
                               console.log(msg.content)
                           }
    }

    ClickableText {
        text: "SEND TEXT"
        onClicked: {
            let a = Object()
            a.channel = "greeting"
            a.content = "HELLO!"
            room.postMessage(a)
            room.dumpInfo()
            beeper.postMessage(root.m)
        }
    }

    ProgressBar {
        id: bar

        anchors.centerIn: parent
        width: 200
        height: 20

        value: 0.8
    }
}
