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

    QtObject {
        id: pCtrl
        readonly property real radius: Math.min(root.width, root.height) / 2
        readonly property real startRad: Qore.geo.radiansFromDegrees(root.startAngle
                                                                     - 90)
        readonly property real endRad: Qore.geo.radiansFromDegress(root.endAngle - 90)
        readonly property polar2d startPolar: Qore.polar2d(radius, startRad)
        readonly property polar2d endPolar: Qore.polar2d(radius, endRad)
        readonly property polar2d startPolar2: Qore.polar2d(radius - root.borderWidth,
                                                            startRad)
        readonly property polar2d endPolar2: Qore.polar2d(radius - root.borderWidth,
                                                          endRad)
        readonly property point startPos: startPolar.toPointF()
        readonly property point endPos: endPolar.toPointF()
        readonly property point startPos2: startPolar2.toPointF()
        readonly property point endPos2: endPolar2.toPointF()
        readonly property bool largeRange: root.endAngle - root.startAngle >= 180
    }

    ShapePath {
        id: shape
        startX: pCtrl.startPos.x
        startY: pCtrl.startPos.y
        PathArc {
            x: pCtrl.endPos.x
            y: pCtrl.endPos.y
            useLargeArc: pCtrl.largeRange
        }
        PathLine {
            x: pCtrl.endPos2.x
            y: pCtrl.endPos2.y
        }
        PathArc {
            x: pCtrl.startPos2.x
            y: pCtrl.startPos2.y
            useLargeArc: pCtrl.largeRange
        }
        PathLine {
            x: pCtrl.startPos.x
            y: pCtrl.startPos.y
        }
        strokeWidth: 0
        fillColor: "cyan"
    }
}
