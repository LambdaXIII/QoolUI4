import QtQuick
import Qool.Chat

MouseArea {
    id: root
    property string text
    property color color: Style.highlight

    hoverEnabled: true

    anchors.fill: parent

    // propagateComposedEvents: true
    // preventStealing: false
    acceptedButtons: Qt.NoButton

    onEntered: {
        if (!text)
            return
        // console.log("entered")
        let a = {
            "channel": "qooltip",
            "content": root.text,
            "color": root.color
        }
        GlobalChatRoom.postMessage(a)
    }

    // onExited: {
    //     if (!text)
    //         return
    //     // console.log("exited")
    //     let a = Object()
    //     a.channel = "qooltip"
    //     GlobalChatRoom.postMessage(a)
    // }
}
