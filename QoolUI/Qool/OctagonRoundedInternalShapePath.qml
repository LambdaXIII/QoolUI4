import QtQuick
import QtQuick.Shapes
import Qool

ShapePath {
    id: root

    property QoolBoxShapeControl control

    joinStyle: ShapePath.BevelJoin
    strokeWidth: 0
    strokeColor: "transparent"

    startX: control.intTLx
    startY: control.intTLy

    readonly property QtObject pCtrl: QtObject {
        readonly property real borderFix: control.borderShrinkSize
                                          - control.safeBorderWidth
        readonly property real intTR: Math.max(0,
                                               control.safeTR + borderFix)
        readonly property real intTL: Math.max(0,
                                               control.safeTL + borderFix)
        readonly property real intBL: Math.max(0,
                                               control.safeBL + borderFix)
        readonly property real intBR: Math.max(0,
                                               control.safeBR + borderFix)
    }

    PathLine {
        x: control.intTRx
        y: control.intTRy
    }

    PathArc {
        radiusX: pCtrl.intTR
        radiusY: pCtrl.intTR
        relativeX: radiusX
        relativeY: radiusY
    }

    PathLine {
        x: control.intRBx
        y: control.intRBy
    }

    PathArc {
        radiusX: pCtrl.intBR
        radiusY: pCtrl.intBR
        x: control.intBRx
        y: control.intBRy
    }

    PathLine {
        x: control.intBLx
        y: control.intBLy
    }

    PathArc {
        radiusX: pCtrl.intBL
        radiusY: pCtrl.intBL
        x: control.intLBx
        y: control.intLBy
    }

    PathLine {
        x: control.intLTx
        y: control.intLTy
    }

    PathArc {
        radiusX: pCtrl.intTL
        radiusY: pCtrl.intTL
        x: control.intTLx
        y: control.intTLy
    }
}
