import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property real startAngle
    property real endAngle

    property real borderWidth: 2

    horizontalAlignment: Shape.AlignHCenter
    verticalAlignment: Shape.AlignVCenter

    ShapeControl {
        id: control
        property bool useLargeArc: (root.endAngle - root.startAngle) > 180
        CircleGadget {
            id: out_circle
            center: control.center
            radius: control.shortEdge / 2
            property point startPos: pointFromAngle(root.startAngle)
            property point endPos: pointFromAngle(root.endAngle)
        }

        CircleGadget {
            id: in_circle
            center: control.center
            radius: control.shortEdge / 2 - root.borderWidth
            property point startPos: pointFromAngle(root.startAngle)
            property point endPos: pointFromAngle(root.endAngle)
        }
    }

    ShapePath {
        id: shape
        startX: out_circle.startPos.x
        startY: out_circle.startPos.y
        PathArc {
            x: out_circle.endPos.x
            y: out_circle.endPos.y
            useLargeArc: control.useLargeArc
        }
        PathLine {
            x: in_circle.endPos.x
            y: in_circle.endPos.y
        }
        PathArc {
            x: in_circle.startPos.x
            y: in_circle.startPos.y
            useLargeArc: control.useLargeArc
        }
        PathLine {
            x: out_circle.startPos.x
            y: out_circle.startPos.y
        }
        strokeWidth: 0
        fillColor: "cyan"
    }
}
