import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qool
import Qool.Controls.Components

BasicControl {
    id: root
    property var messages: []
    readonly property bool empty: !messages || messages.length === 0
    title: qsTr("消息日志")

    Component {
        id: msgRow
        RowLayout {
            width: ListView.view.width
            spacing: 8
            Text {
                text: Qt.formatDateTime(modelData.created, "hh:mm:ss")
                font.pixelSize: Style.controlTextSize
                color: Style.accent
            }
            Text {
                text: modelData.content
                font.pixelSize: Style.controlTextSize
                color: Style.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

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
            delegate: msgRow
            onCountChanged: if (count > 0)
                positionViewAtEnd()
        }
        Text {
            anchors.centerIn: parent
            visible: root.empty
            text: qsTr("点击频道终端展示消息历史")
            color: Style.infoColor
            opacity: 0.5
        }
    }
}
