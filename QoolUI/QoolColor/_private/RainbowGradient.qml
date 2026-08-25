import QtQuick
import QtQuick.Shapes
import Qool

LinearGradient {
    id: root

    property real saturation: 1
    property real value: 1
    property real alpha: 1
    property bool horizontal: true
    property real width: 100
    property real height: 100
    property bool mirrored: false

    x1: root.horizontal && root.mirrored ? width : 0
    x2: root.horizontal ? (root.mirrored ? 0 : width) : 0
    y1: root.horizontal ? 0 : height

    function get_color(p) {
        return Qt.hsva(p, root.saturation, root.value, root.alpha);
    }

    GradientStop {
        position: 0.0
        color: get_color(0.0)
    }
    GradientStop {
        position: 0.1
        color: get_color(0.1)
    }
    GradientStop {
        position: 0.2
        color: get_color(0.2)
    }
    GradientStop {
        position: 0.3
        color: get_color(0.3)
    }
    GradientStop {
        position: 0.4
        color: get_color(0.4)
    }
    GradientStop {
        position: 0.5
        color: get_color(0.5)
    }
    GradientStop {
        position: 0.6
        color: get_color(0.6)
    }
    GradientStop {
        position: 0.7
        color: get_color(0.7)
    }
    GradientStop {
        position: 0.8
        color: get_color(0.8)
    }
    GradientStop {
        position: 0.9
        color: get_color(0.9)
    }
    GradientStop {
        position: 1
        color: get_color(1.0)
    }
}
