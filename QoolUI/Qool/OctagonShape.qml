import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property OctagonSettings settings: OctagonSettings {}
    property OctagonShapeHelper shapeControl: OctagonShapeHelper {
        settings: root.settings
        target: root
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: fillShape
        fillColor: root.settings.fillColor

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
    }

    Timer {
        id: debugTimer
        interval: 1000
        onTriggered: shapeControl.dumpPoints()
    }

    Component.onCompleted: {
        debugTimer.start()
    }
}
