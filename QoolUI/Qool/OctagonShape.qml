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

        startX: shapeControl.externalTLx
        startY: shapeControl.externalTLy

        PathLine {
            x: shapeControl.externalTRx
            y: shapeControl.externalTRy
        }
        PathLine {
            x: shapeControl.externalRTx
            y: shapeControl.externalRTy
        }
        PathLine {
            x: shapeControl.externalRBx
            y: shapeControl.externalRBy
        }
        PathLine {
            x: shapeControl.externalBRx
            y: shapeControl.externalBRy
        }
        PathLine {
            x: shapeControl.externalBLx
            y: shapeControl.externalBLy
        }
        PathLine {
            x: shapeControl.externalLBx
            y: shapeControl.externalLBy
        }
        PathLine {
            x: shapeControl.externalLTx
            y: shapeControl.externalLTy
        }
        PathLine {
            x: shapeControl.externalTLx
            y: shapeControl.externalTLy
        }
        //inner
        PathMove {
            x: shapeControl.internalTLx
            y: shapeControl.internalTLy
        }
        PathLine {
            x: shapeControl.internalTRx
            y: shapeControl.internalTRy
        }
        PathLine {
            x: shapeControl.internalRTx
            y: shapeControl.internalRTy
        }
        PathLine {
            x: shapeControl.internalRBx
            y: shapeControl.internalRBy
        }
        PathLine {
            x: shapeControl.internalBRx
            y: shapeControl.internalBRy
        }
        PathLine {
            x: shapeControl.internalBLx
            y: shapeControl.internalBLy
        }
        PathLine {
            x: shapeControl.internalLBx
            y: shapeControl.internalLBy
        }
        PathLine {
            x: shapeControl.internalLTx
            y: shapeControl.internalLTy
        }
        PathLine {
            x: shapeControl.internalTLx
            y: shapeControl.internalTLy
        }
    }

    ShapePath {
        id: fillShape
        fillColor: root.settings.fillColor
        strokeWidth: 0
        strokeColor: "transparent"
        joinStyle: ShapePath.BevelJoin

        startX: shapeControl.internalTLx
        startY: shapeControl.internalTLy

        PathLine {
            x: shapeControl.internalTRx
            y: shapeControl.internalTRy
        }
        PathLine {
            x: shapeControl.internalRTx
            y: shapeControl.internalRTy
        }
        PathLine {
            x: shapeControl.internalRBx
            y: shapeControl.internalRBy
        }
        PathLine {
            x: shapeControl.internalBRx
            y: shapeControl.internalBRy
        }
        PathLine {
            x: shapeControl.internalBLx
            y: shapeControl.internalBLy
        }
        PathLine {
            x: shapeControl.internalLBx
            y: shapeControl.internalLBy
        }
        PathLine {
            x: shapeControl.internalLTx
            y: shapeControl.internalLTy
        }
        PathLine {
            x: shapeControl.internalTLx
            y: shapeControl.internalTLy
        }
    } //fill shape

    Timer {
        id: debugTimer
        interval: 1000
        onTriggered: shapeControl.dumpInfo()
    }

    Component.onCompleted: {
        debugTimer.start()
    }
}
