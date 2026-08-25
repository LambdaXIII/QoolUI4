import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

Item {
    id: root

    // 纯预览元素：只渲染色面（左半实色/右半原色+白衬底），
    // 不提供任何样式外观（无边框、无前景对比装饰），宿主自行包装。

    // 默认状态自洽：默认实例自带默认色，独立使用成立。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Qt.alpha(Style.highlight, 0.5)
    }

    property real radius: 10

    property color backgroundColor1: "black"
    property color backgroundColor2: "white"

    property real horizontalRatio: 0.5
    property real verticalRatio: 0.5

    implicitWidth: 150
    implicitHeight: 50

    Shape {
        id: mainShape
        width: Math.max(parent.width, root.radius * 2)
        height: Math.max(parent.height, root.radius * 2)
        anchors.centerIn: parent

        readonly property real maxW1: width - root.radius
        readonly property real maxH1: height - root.radius

        readonly property real w1: Qore.bound(root.radius, width * root.horizontalRatio, maxW1)
        readonly property real w2: width * (1 - root.horizontalRatio)
        readonly property real h1: Qore.bound(root.radius, height * root.verticalRatio, maxH1)
        readonly property real h2: height * (1 - root.verticalRatio)

        ShapePath {
            // id: topBGPath
            PathRectangle {
                width: mainShape.weight
                height: mainShape.h1
                topLeftRadius: root.radius
                topRightRadius: root.radius
            }
            strokeWidth: 0
            fillColor: root.backgroundColor1
        }//top

        ShapePath {
            // id: bottomBGPath
            PathRectangle {
                width: mainShape.width
                height: mainShape.h2
                y: mainShape.h1
                bottomLeftRadius: root.radius
                bottomRightRadius: root.radius
            }
            strokeWidth: 0
            fillColor: root.backgroundColor2
        }//bottom

        ShapePath {
            // id: leftArea
            PathRectangle {
                width: mainShape.w1
                height: mainShape.height
                topLeftRadius: root.radius
                bottomLeftRadius: root.radius
            }
            strokeWidth: 0
            fillColor: root.colorAssistant.solidColor
        }//left

        ShapePath {
            // id: rightArea
            PathRectangle {
                width: mainShape.w2
                height: mainShape.height
                x: mainShape.w1
                topRightRadius: root.radius
                bottomRightRadius: root.radius
            }
            strokeWidth: 0
            fillColor: root.colorAssistant.color
        }//right

    } //mainShape
}
