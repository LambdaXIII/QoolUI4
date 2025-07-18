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

    OctagonExternalShapePath {
        id: borderShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.borderColor
    }

    OctagonInternalShapePath {
        id: fillShape
        control: root.control
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.control.settings.fillColor
    }

    containmentMask: root.control
}
