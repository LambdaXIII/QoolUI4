import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Window
import Qool

AbstractButton {
    id: root

    // 动画开关接口，供宿主覆盖；未覆盖时兜底父级或 Style.animationEnabled
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property real buttonSpacing: 8
    property real windowCutSize: Style.windowCutSize
    property color borderColor: Style.shadow
    property color fillColor: root.down ? Style.highlight : Style.negative

    hoverEnabled: true

    z: -90

    TriangleGadget {
        id: pCtrl
        readonly property real size: root.windowCutSize - root.buttonSpacing

        pointAx: 0
        pointAy: 0
        pointBx: size
        pointBy: 0
        pointCx: 0
        pointCy: size

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

            startX: pCtrl.pointAx
            startY: pCtrl.pointAy
            PathLine {
                x: pCtrl.pointBx
                y: pCtrl.pointBy
            }
            PathLine {
                x: pCtrl.pointCx
                y: pCtrl.pointCy
            }
            PathLine {
                x: pCtrl.pointAx
                y: pCtrl.pointAy
            }
        }
    } //contentItem
}
