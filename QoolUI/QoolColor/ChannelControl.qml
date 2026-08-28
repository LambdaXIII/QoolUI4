import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool
import Qool.Color

Control {
    id: root

    property int channel: ColorHQ.HSLHue
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }
    property real value
    property bool readOnly: false

    property int orientation: Qt.Horizontal
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    contentItem: ColumnLayout {
        spacing: 2
        Loader {
            active: root.vertical
            sourceComponent: ChannelBoxSlider {
                objectName: "vslider"

                channel: root.channel
                colorAssistant: root.colorAssistant
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ChannelEdit {
            objectName: "edit"
            Layout.fillWidth: true
            orientation: root.orientation
            tagOnTop: true
            channel: root.channel
            colorAssistant: root.colorAssistant
            readOnly: root.readOnly
        }

        Loader {
            active: root.horizontal
            sourceComponent: ChannelCrystalSlider {
                objectName: "hslider"

                channel: root.channel
                colorAssistant: root.colorAssistant
            }
            Layout.fillWidth: true
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
            root.value = proxy.value;
        }
    }

    Connections {
        target: root
        function onValueChanged() {
            proxy.value = root.value;
        }
    }

    // 播种：现读真实通道值（proxy 观察已建立）；NaN 不写防污染属性。
    Component.onCompleted: {
        const v = proxy.value;
        if (!Number.isNaN(v))
            root.value = v;
    }
}
