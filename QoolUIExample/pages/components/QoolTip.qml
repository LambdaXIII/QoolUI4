import QtQuick
import Qool.Chat

MouseArea {
    id: root
    property string text
    hoverEnabled: true

    anchors.fill: parent

    propagateComposedEvents: true

    onEntered: {
        if (!text)
            return
        // console.log("entered")
        let a = {
            "channel": "qooltip",
            "content": root.text,
            "color": "red"
        }
        GlobalChatRoom.postMessage(a)
    }

    onExited: {
        if (!text)
            return
        // console.log("exited")
        let a = Object()
        a.channel = "qooltip"
        GlobalChatRoom.postMessage(a)
    }
}
