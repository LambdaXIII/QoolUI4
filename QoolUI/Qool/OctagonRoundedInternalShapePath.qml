import QtQuick
import QtQuick.Shapes
import Qool

ShapePath {
    id: root

    property OctagonShapeHelper shapeControl

    joinStyle: ShapePath.BevelJoin
    strokeWidth: 0
    strokeColor: "transparent"

    startX: shapeControl.intTLx
    startY: shapeControl.intTLy

    readonly property QtObject pCtrl: QtObject {
        readonly property real borderFix: shapeControl.borderShrinkSize
                                          - shapeControl.safeBorderWidth
        readonly property real intTR: Math.max(0,
                                               shapeControl.safeTR + borderFix)
        readonly property real intTL: Math.max(0,
                                               shapeControl.safeTL + borderFix)
        readonly property real intBL: Math.max(0,
                                               shapeControl.safeBL + borderFix)
        readonly property real intBR: Math.max(0,
                                               shapeControl.safeBR + borderFix)
    }

    PathLine {
        x: shapeControl.intTRx
        y: shapeControl.intTRy
    }

    PathArc {
        radiusX: pCtrl.intTR
        radiusY: pCtrl.intTR
        relativeX: radiusX
        relativeY: radiusY
    }

    PathLine {
        x: shapeControl.intRBx
        y: shapeControl.intRBy
    }

    PathArc {
        radiusX: pCtrl.intBR
        radiusY: pCtrl.intBR
        x: shapeControl.intBRx
        y: shapeControl.intBRy
    }

    PathLine {
        x: shapeControl.intBLx
        y: shapeControl.intBLy
    }

    PathArc {
        radiusX: pCtrl.intBL
        radiusY: pCtrl.intBL
        x: shapeControl.intLBx
        y: shapeControl.intLBy
    }

    PathLine {
        x: shapeControl.intLTx
        y: shapeControl.intLTy
    }

    PathArc {
        radiusX: pCtrl.intTL
        radiusY: pCtrl.intTL
        x: shapeControl.intTLx
        y: shapeControl.intTLy
    }
}
