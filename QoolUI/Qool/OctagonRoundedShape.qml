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

    ShapePath {
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

        PathArc {
            radiusX: shapeControl.safeTR
            radiusY: shapeControl.safeTR
            x: shapeControl.externalRTx
            y: shapeControl.externalRTx
        }

        PathLine {
            x: shapeControl.externalRBx
            y: shapeControl.externalRBy
        }

        PathArc {
            radiusX: shapeControl.safeBR
            radiusY: shapeControl.safeBR
            x: shapeControl.externalBRx
            y: shapeControl.externalBRy
        }

        PathLine {
            x: shapeControl.externalBLx
            y: shapeControl.externalBLy
        }

        PathArc {
            radiusX: shapeControl.safeBL
            radiusY: shapeControl.safeBL
            x: shapeControl.externalLBx
            y: shapeControl.externalLBy
        }

        PathLine {
            x: shapeControl.externalLTx
            y: shapeControl.externalLTy
        }

        PathArc {
            radiusX: shapeControl.safeTL
            radiusY: shapeControl.safeTL
            x: shapeControl.externalTLx
            y: shapeControl.externalTLy
        }
    }
}
