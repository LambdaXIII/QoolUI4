
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool
import Qool.Color

Control {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorHQ.HSLHue
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }
    property real value
    property bool readOnly: false

    property int orientation: Qt.Horizontal
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    contentItem: Loader {
        sourceComponent: root.horizontal ? horizontalLayout : verticalLayout
    }

    Component {
        id: horizontalLayout

        ColumnLayout {
            spacing: 0

            ColorChannelEdit {
                objectName: "edit"
                Layout.fillWidth: true
                animationEnabled: root.animationEnabled
                channel: root.channel
                colorAssistant: root.colorAssistant
                readOnly: root.readOnly
            }

            ColorChannelSlider {
                objectName: "hslider"
                Layout.fillWidth: true
                animationEnabled: root.animationEnabled
                channel: root.channel
                colorAssistant: root.colorAssistant
            }
        }
    }

    Component {
        id: verticalLayout

        ColumnLayout {
            spacing: 0

            ColorChannelVerticalSlider {
                objectName: "vslider"
                Layout.fillWidth: true
                Layout.fillHeight: true
                animationEnabled: root.animationEnabled
                channel: root.channel
                colorAssistant: root.colorAssistant
            }

            ColorChannelEdit {
                objectName: "edit"
                Layout.fillWidth: true
                orientation: Qt.Vertical
                tagOnTop: true
                animationEnabled: root.animationEnabled
                channel: root.channel
                colorAssistant: root.colorAssistant
                readOnly: root.readOnly
            }
        }
    }

    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorHQ.channelNameF(root.channel)
    }

    Connections {
        target: proxy
        function onValueChanged() {
            root.value = proxy.value
        }
    }

    Connections {
        target: root
        function onValueChanged() {
            proxy.value = root.value
        }
    }

    // 播种：现读真实通道值（proxy 观察已建立）；NaN 不写防污染属性。
    Component.onCompleted: {
        const v = proxy.value
        if (!Number.isNaN(v))
            root.value = v
    }
}
