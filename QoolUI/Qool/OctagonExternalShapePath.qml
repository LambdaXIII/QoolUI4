import QtQuick
import QtQuick.Shapes
import Qool

ShapePath {
    id: strokeShape
    property OctagonShapeHelper control

    joinStyle: ShapePath.BevelJoin
    pathHints: ShapePath.PahtLinear | ShapePath.PathNonOverlappingControlPointTriangles

    startX: root.control.extTLx
    startY: root.control.extTLy

    PathLine {
        x: root.control.extTRx
        y: root.control.extTRy
    }
    PathLine {
        x: root.control.extRTx
        y: root.control.extRTy
    }
    PathLine {
        x: root.control.extRBx
        y: root.control.extRBy
    }
    PathLine {
        x: root.control.extBRx
        y: root.control.extBRy
    }
    PathLine {
        x: root.control.extBLx
        y: root.control.extBLy
    }
    PathLine {
        x: root.control.extLBx
        y: root.control.extLBy
    }
    PathLine {
        x: root.control.extLTx
        y: root.control.extLTy
    }
    PathLine {
        x: root.control.extTLx
        y: root.control.extTLy
    }
    //inner
    PathMove {
        x: root.control.intTLx
        y: root.control.intTLy
    }
    PathLine {
        x: root.control.intTRx
        y: root.control.intTRy
    }
    PathLine {
        x: root.control.intRTx
        y: root.control.intRTy
    }
    PathLine {
        x: root.control.intRBx
        y: root.control.intRBy
    }
    PathLine {
        x: root.control.intBRx
        y: root.control.intBRy
    }
    PathLine {
        x: root.control.intBLx
        y: root.control.intBLy
    }
    PathLine {
        x: root.control.intLBx
        y: root.control.intLBy
    }
    PathLine {
        x: root.control.intLTx
        y: root.control.intLTy
    }
    PathLine {
        x: root.control.intTLx
        y: root.control.intTLy
    }
}
