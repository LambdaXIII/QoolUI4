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

    OctagonExternalShapePath {
        id: borderShape
        shapeControl: root.shapeControl
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.shapeControl.settings.borderColor
    }

    OctagonInternalShapePath {
        id: fillShape
        shapeControl: root.shapeControl
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.shapeControl.settings.fillColor
    }
}
