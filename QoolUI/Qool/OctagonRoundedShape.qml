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

    property alias fillItem: fillShape.fillItem

    OctagonRoundedExternalShapePath {
        shapeControl: root.shapeControl
        fillColor: root.settings.borderColor
    }

    OctagonRoundedInternalShapePath {
        id: fillShape
        shapeControl: root.shapeControl
        fillColor: root.settings.fillColor
    }
}
