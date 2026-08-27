import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    //!! 不保证长宽一致
    width: 20
    height: 20

    property real radius: box.halfHeight
    property real borderWidth: 2
    property real borderSpace: 2
    property color color: Style.accent
    property color borderColor: color

    preferredRendererType: Shape.CurveRenderer

    ShapeControl {
        RectGadget {
            id: box
        }
    }

    ShapePath {
        PathRectangle {
            radius: root.radius
            width: box.width
            height: box.height
        }

        PathRectangle {
            readonly property real shrink: root.borderWidth
            radius: root.radius - shrink
            width: box.width - shrink * 2
            height: box.height - shrink * 2
            x: box.x + shrink
            y: box.y + shrink
        }
        strokeWidth: 0
        fillColor: root.borderColor
    }

    ShapePath {
        PathRectangle {
            readonly property real shrink: root.borderWidth + root.borderSpace
            radius: root.radius - shrink
            width: box.width - shrink * 2
            height: box.height - shrink * 2
            x: box.x + shrink
            y: box.y + shrink
        }
        strokeWidth: 0
        fillColor: root.color
    }
}
