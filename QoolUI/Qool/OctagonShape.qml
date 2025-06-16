import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property OctagonSettings settings: OctagonSettings {
        borderWidth: 10
    }
    property OctagonShapeHelper shapeControl: OctagonShapeHelper {
        settings: root.settings
        target: root
    }

    // preferredRendererType: Shape.CurveRenderer
    ShapePath {
        id: strokeShape
        fillColor: root.settings.borderColor
        strokeWidth: 0
        strokeColor: "transparent"
        joinStyle: ShapePath.BevelJoin

        startX: root.shapeControl.extTLx
        startY: root.shapeControl.extTLy

        PathLine {
            x: root.shapeControl.extTRx
            y: root.shapeControl.extTRy
        }
        PathLine {
            x: root.shapeControl.extRTx
            y: root.shapeControl.extRTy
        }
        PathLine {
            x: root.shapeControl.extRBx
            y: root.shapeControl.extRBy
        }
        PathLine {
            x: root.shapeControl.extBRx
            y: root.shapeControl.extBRy
        }
        PathLine {
            x: root.shapeControl.extBLx
            y: root.shapeControl.extBLy
        }
        PathLine {
            x: root.shapeControl.extLBx
            y: root.shapeControl.extLBy
        }
        PathLine {
            x: root.shapeControl.extLTx
            y: root.shapeControl.extLTy
        }
        PathLine {
            x: root.shapeControl.extTLx
            y: root.shapeControl.extTLy
        }
        //inner
        PathMove {
            x: root.shapeControl.intTLx
            y: root.shapeControl.intTLy
        }
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
    }

    ShapePath {
        id: fillShape
        fillColor: root.settings.fillColor
        strokeWidth: 0
        strokeColor: "transparent"
        joinStyle: ShapePath.BevelJoin

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
}
