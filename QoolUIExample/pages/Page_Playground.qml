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
        // name: "A1"
        Beeper {
            id: beeper
            onMessageRecieved: msg => {
                                   console.log(msg)
                               }
        }
    }

    ClickableText {
        text: "SEND TEXT"
        onClicked: {
            room.postMessage(root.m)
            console.log(room.beepers)
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
