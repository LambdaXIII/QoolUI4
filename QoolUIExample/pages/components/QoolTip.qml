// TODO(将来重设计): 全面重新设计整个 QoolTip 机制（本件 + QoolTipPanel.qml；
// 当前仅保证无明显非法、可使用）
import QtQuick
import Qool.Chat

MouseArea {
    id: root
    //TODO:实现有遮蔽Bug，考虑HoverHandler等替代方案。
    property string text
    property color color: Style.highlight

    hoverEnabled: true

    anchors.fill: parent

    // propagateComposedEvents: true
    // preventStealing: false
    acceptedButtons: Qt.NoButton

    onEntered: {
        if (!text)
            return;
        // console.log("entered")
        let a = {
            "channel": "qooltip",
            "content": root.text,
            "color": root.color
        };
        GlobalChatRoom.postMessage(a);
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
