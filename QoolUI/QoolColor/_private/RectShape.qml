import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property real radius: 4
    property real borderWidth: 1
    property alias borderColor: rect.strokeColor
    property alias color: rect.fillColor
    property alias fillGradient: rect.fillGradient

    ShapePath {
        id: rect
        readonly property real shrinkSize: root.borderWidth / 2
        PathRectangle {
            x: rect.shrinkSize
            y: rect.shrinkSize
            width: root.width - root.borderWidth
            height: root.height - root.borderWidth
            radius: root.radius
        }
        strokeWidth: root.borderWidth
    }
}
