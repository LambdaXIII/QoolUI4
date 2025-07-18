import QtQuick
import QtQuick.Shapes
import Qool

Shape {
    id: root

    property QoolBoxSettings settings: QoolBoxSettings {
        // borderWidth: 10
    }
    readonly property QoolBoxShapeControl control: QoolBoxShapeControl {
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
