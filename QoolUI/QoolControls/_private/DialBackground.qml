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
