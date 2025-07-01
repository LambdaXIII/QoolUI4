import QtQuick
import QtQuick.Shapes
import Qool

ShapePath {
    id: root
    property OctagonShapeHelper shapeControl

    strokeWidth: 0
    strokeColor: "transparent"
    joinStyle: ShapePath.BevelJoin
    pathHints: ShapePath.PahtLinear | ShapePath.PathNonOverlappingControlPointTriangles
               | ShapePath.PathConvex

    startX: root.shapeControl.intTLx
    startY: root.shapeControl.intTLy

    PathLine {
        x: root.shapeControl.intTRx
        y: root.shapeControl.intTRy
    }
    PathLine {
        x: root.shapeControl.intRTx
        y: root.shapeControl.intRTy
    }
    PathLine {
        x: root.shapeControl.intRBx
        y: root.shapeControl.intRBy
    }
    PathLine {
        x: root.shapeControl.intBRx
        y: root.shapeControl.intBRy
    }
    PathLine {
        x: root.shapeControl.intBLx
        y: root.shapeControl.intBLy
    }
    PathLine {
        x: root.shapeControl.intLBx
        y: root.shapeControl.intLBy
    }
    PathLine {
        x: root.shapeControl.intLTx
        y: root.shapeControl.intLTy
    }
    PathLine {
        x: root.shapeControl.intTLx
        y: root.shapeControl.intTLy
    }
} //fill shape
