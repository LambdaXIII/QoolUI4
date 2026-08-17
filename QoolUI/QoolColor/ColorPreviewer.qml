pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool

Item {
    id: root

    // 纯预览元素：只渲染色面（左半实色/右半原色+白衬底），
    // 不提供任何样式外观（无边框、无前景对比装饰），宿主自行包装。

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Qt.alpha(Style.highlight, 0.5)
    }

    property real radius: 10

    Shape {
        id: mainShape
        anchors.fill: parent

        // 右下衬底：半透明色与白色背景的混合效果（v3 whiteBg）。
        ShapePath {
            id: whiteUnderlay
            startX: root.width / 2
            startY: root.height / 2
            PathLine {
                x: root.width
                y: root.height / 2
            }
            PathLine {
                x: root.width
                y: root.height - root.radius
            }
            PathArc {
                x: root.width - root.radius
                y: root.height
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: root.height
            }
            PathLine {
                x: root.width / 2
                y: root.height / 2
            }
            strokeColor: "transparent"
            fillColor: "white"
        } //whiteUnderlay

        // 左半：实色（去 alpha）。
        ShapePath {
            id: leftPath
            startX: root.width / 2
            startY: 0
            PathLine {
                x: root.width / 2
                y: root.height
            }
            PathLine {
                x: root.radius
                y: root.height
            }
            PathArc {
                x: 0
                y: root.height - root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: 0
                y: root.radius
            }
            PathArc {
                x: root.radius
                y: 0
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: 0
            }
            fillColor: root.colorAssistant.solidColor
            strokeWidth: 0
            strokeColor: "transparent"
        } //leftPath

        // 右半：带 alpha 的原色（上半透明衬底、下半白衬底）。
        ShapePath {
            id: rightPath
            startX: root.width / 2
            startY: root.height
            PathLine {
                x: root.width / 2
                y: 0
            }
            PathLine {
                x: root.width - root.radius
                y: 0
            }
            PathArc {
                x: root.width
                y: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width
                y: root.height - root.radius
            }
            PathArc {
                x: root.width - root.radius
                y: root.height
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width / 2
                y: root.height
            }
            fillColor: root.colorAssistant.color
            strokeWidth: 0
            strokeColor: "transparent"
        } //rightPath
    } //mainShape
}
