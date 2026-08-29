import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Controls.Components

BasicControl {
    id: root
    required property var messages      // 外部传入：某卡的 logger.messages
    readonly property bool empty: !messages || messages.length === 0
    title: qsTr("消息日志")

    contentItem: Item {
        implicitHeight: 340
        ListView {
            id: logView
            anchors.fill: parent
            visible: !root.empty
            clip: true
            spacing: 2
            model: root.messages
            ScrollIndicator.vertical: ScrollIndicator {}
            // 本 delegate 无 required property → modelData context 注入正常（02 的根因结论）
            delegate: RowLayout {
                width: ListView.view.width
                spacing: 8
                Text { text: Qt.formatDateTime(modelData.created, "hh:mm:ss"); font.pixelSize: Style.controlTextSize; color: Style.accent }
                Text { text: modelData.content; font.pixelSize: Style.controlTextSize; color: Style.text; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            onCountChanged: if (count > 0) positionViewAtEnd()
        }
        Text {
            anchors.centerIn: parent
            visible: root.empty
            text: qsTr("暂无消息")
            color: Style.text
            opacity: 0.5
        }
    }
}
