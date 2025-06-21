import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Window
import Qool

AbstractButton {
    id: root

    property bool animationEnabled: parent?.animationEnable ?? QoolConstants.animationEnabled
    property real buttonSpacing: 8
    property real windowCutSize: QoolConstants.windowCutSize
    property color borderColor: root.palette.shadow
    property color fillColor: root.down ? root.palette.highlight : QoolConstants.negativeColor

    hoverEnabled: true

    z: -90

    ShapeHelper {
        id: pCtrl
        readonly property real size: root.windowCutSize - root.buttonSpacing

        point0x: 0
        point0y: 0
        point1x: size
        point1y: 0
        point2x: 0
        point2y: size

        function contains(p: point): bool {
            if (p.x < 0 || p.x > size || p.y < 0 || p.y > size)
                return false;
            return p.x + p.y <= size;
        }
    }
    containmentMask: pCtrl
    contentItem: Shape {
        containsMode: Shape.FillContains
        ShapePath {
            strokeWidth: 1
            strokeColor: root.borderColor
            fillColor: root.fillColor
            fillRule: ShapePath.WindingFill
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: pCtrl.point0x
            startY: pCtrl.point0y
            PathLine {
                x: pCtrl.point1x
                y: pCtrl.point1y
            }
            PathLine {
                x: pCtrl.point2x
                y: pCtrl.point2y
            }
            PathLine {
                x: pCtrl.point0x
                y: pCtrl.point0y
            }
        }
    } //contentItem
}
