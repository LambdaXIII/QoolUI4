import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

LinearGradient {
    id: root

    property bool horizontal: true
    property real width: 100
    property real height: 100
    property int channel: 0
    property bool mirrored: false

    // 浓端锚满值侧（勿改 y1:height——那会把浓端放 0 值侧）。
    x1: root.horizontal && root.mirrored ? 0 : width
    x2: root.horizontal && !root.mirrored ? 0 : width
    y1: 0
    y2: root.horizontal ? 0 : height
    function get_color(p) {
        return Qt.hsva(p, root.saturation, root.value, root.alpha);
    }

    function get_fromColor(channel) {
        switch (channel) {
        case ColorHQ.Red:
        case ColorHQ.Green:
        case ColorHQ.Blue:
        case ColorHQ.HSVValue:
        case ColorHQ.HSLLightness:
        case ColorHQ.Alpha:
            return "transparent";
        case ColorHQ.Cyan:
        case ColorHQ.Magenta:
        case ColorHQ.Yellow:
        case ColorHQ.Black:
            return "black";
        }
        return "white";
    }

    function get_toColor(channel) {
        return ColorHQ.channelColor(channel);
    }

    property color fromColor: get_fromColor(root.channel)
    property color toColor: get_toColor(root.channel)

    GradientStop {
        position: 0.0
        color: root.toColor
    }
    GradientStop {
        position: 1
        color: root.fromColor
    }
}
