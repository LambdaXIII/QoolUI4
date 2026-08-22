// 色相轨道：覆写基类 gradient 为 11 档彩虹 hsva(p,1,1,1)；
// 锚定几何同基类（gradientAnchors 单点维护）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import "ColorChannelSliderColors.js" as Colors

ColorChannelSliderTrack {
    id: root

    gradient: LinearGradient {
        readonly property var geo: Colors.gradientAnchors(
                                       root.gradientWidth, root.gradientHeight,
                                       root.horizontal, root.mirrored)
        x1: geo.x1
        y1: geo.y1
        x2: geo.x2
        y2: geo.y2
        GradientStop {
            position: 0
            color: Qt.hsva(0, 1, 1, 1)
        }
        GradientStop {
            position: 0.1
            color: Qt.hsva(0.1, 1, 1, 1)
        }
        GradientStop {
            position: 0.2
            color: Qt.hsva(0.2, 1, 1, 1)
        }
        GradientStop {
            position: 0.3
            color: Qt.hsva(0.3, 1, 1, 1)
        }
        GradientStop {
            position: 0.4
            color: Qt.hsva(0.4, 1, 1, 1)
        }
        GradientStop {
            position: 0.5
            color: Qt.hsva(0.5, 1, 1, 1)
        }
        GradientStop {
            position: 0.6
            color: Qt.hsva(0.6, 1, 1, 1)
        }
        GradientStop {
            position: 0.7
            color: Qt.hsva(0.7, 1, 1, 1)
        }
        GradientStop {
            position: 0.8
            color: Qt.hsva(0.8, 1, 1, 1)
        }
        GradientStop {
            position: 0.9
            color: Qt.hsva(0.9, 1, 1, 1)
        }
        GradientStop {
            position: 1
            color: Qt.hsva(1, 1, 1, 1)
        }
    }
}
