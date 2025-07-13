import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property OctagonSettings settings: OctagonSettings {
        borderWidth: 10
    }
    readonly property OctagonShapeHelper control: OctagonShapeHelper {
        settings: root.settings
        target: root
    }

    property alias fillItem: fillShape.fillItem

    OctagonRoundedExternalShapePath {
        control: root.control
        fillColor: root.settings.borderColor
    }

    OctagonRoundedInternalShapePath {
        id: fillShape
        control: root.control
        fillColor: root.settings.fillColor
    }

    containsMode: Shape.FillContains
}
