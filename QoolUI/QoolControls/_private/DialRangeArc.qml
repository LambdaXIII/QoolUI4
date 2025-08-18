import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property real startAngle: -120
    property real endAngle: 120

    property real borderWidth: Math.max(4, Math.min(root.width,
                                                    root.height) * 0.05)

    property color lowColor: "green"
    property color midColor: "yellow"
    property color highColor: "red"

    ShapeControl {
        id: control
        property bool useLargeArc: (root.endAngle - root.startAngle) > 180

        CircleGadget {
            id: oCircle
            CirclePoint {
                id: oStart
                angle: root.startAngle - 90
            }
            CirclePoint {
                id: oEnd
                angle: root.endAngle - 90
            }
        }
        CircleGadget {
            id: iCircle
            radius: oCircle.radius - root.borderWidth
            CirclePoint {
                id: iStart
                angle: root.startAngle - 90
            }
            CirclePoint {
                id: iEnd
                angle: root.endAngle - 90
            }
        }
    }

    ShapePath {
        id: shape
        startX: oStart.x
        startY: oStart.y
        PathArc {
            x: oEnd.x
            y: oEnd.y
            radiusX: oCircle.radius
            radiusY: oCircle.radius
            useLargeArc: control.useLargeArc
        }
        PathArc {
            x: iEnd.x
            y: iEnd.y
            radiusX: root.borderWidth / 2
            radiusY: root.borderWidth / 2
        }
        PathArc {
            x: iStart.x
            y: iStart.y
            radiusX: iCircle.radius
            radiusY: iCircle.radius
            direction: PathArc.Counterclockwise
            useLargeArc: control.useLargeArc
        }
        PathArc {
            x: oStart.x
            y: oStart.y
            radiusX: root.borderWidth / 2
            radiusY: root.borderWidth / 2
        }
        strokeWidth: 0
        fillGradient: ConicalGradient {
            id: grad
            centerX: control.center.x
            centerY: control.center.y
            angle: 90 - root.endAngle - 10
            property real endPosition: (root.endAngle - root.startAngle) / 360
            GradientStop {
                position: 0 + 10 / 360
                color: root.highColor
            }
            GradientStop {
                position: grad.endPosition / 2
                color: root.midColor
            }
            GradientStop {
                position: grad.endPosition
                color: root.lowColor
            }
        }
    }
}
