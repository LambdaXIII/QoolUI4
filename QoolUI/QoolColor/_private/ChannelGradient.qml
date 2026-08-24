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

    // 渐变向量：起点(y/x1)恒为 position 0（通道浓色=满值端），终点为
    // position 1（0 值端）。水平随镜像换向；竖直自顶(满)向底(空)——
    // 与值轴同向（勿改成 y1: height——那会把浓端放到 0 值侧，方向反）。
    x1: root.horizontal && root.mirrored ? width : 0
    x2: root.horizontal && !root.mirrored ? width : 0
    y1: 0
    y2: root.horizontal ? 0 : height
    function get_color(p) {
        return Qt.hsva(p, root.saturation, root.value, root.alpha);
    }

    function get_fromColor(channel) {
        switch (channel) {
        case ColorNameHQ.Red:
        case ColorNameHQ.Green:
        case ColorNameHQ.Blue:
        case ColorNameHQ.HSVValue:
        case ColorNameHQ.HSLLightness:
        case ColorNameHQ.Alpha:
            return "transparent";
        case ColorNameHQ.Cyan:
        case ColorNameHQ.Magenta:
        case ColorNameHQ.Yellow:
        case ColorNameHQ.Black:
            return "black";
        }
        return "white";
    }

    function get_toColor(channel) {
        return ColorNameHQ.channelColor(channel);
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
