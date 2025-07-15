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
        let a = Object()
        a.content = root.text
        a.channel = "qooltip"
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
