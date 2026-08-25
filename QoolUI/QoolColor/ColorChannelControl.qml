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

    contentItem: ColumnLayout {
        spacing: 2
        Loader {
            active: root.vertical
            sourceComponent: ColorChannelVerticalSlider {
                objectName: "vslider"

                animationEnabled: proxy.animationReallyEnabled
                channel: root.channel
                colorAssistant: root.colorAssistant
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        ColorChannelEdit {
            objectName: "edit"
            Layout.fillWidth: true
            orientation: root.orientation
            tagOnTop: true
            animationEnabled: proxy.animationReallyEnabled
            channel: root.channel
            colorAssistant: root.colorAssistant
            readOnly: root.readOnly
        }

        Loader {
            active: root.horizontal
            sourceComponent: ColorChannelSlider {
                objectName: "hslider"

                animationEnabled: proxy.animationReallyEnabled
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
        property bool seedDone: false
        readonly property bool animationReallyEnabled: proxy.seedDone && root.animationEnabled
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
        proxy.seedDone = true;
    }
}
