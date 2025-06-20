import QtQuick
import Qool

Item {
    id: root

    property OctagonSettings settings: OctagonSettings {
        cutSizeTL: 30
        borderWidth: 5
        borderColor: palette.shadow
        fillColor: palette.base
    }

    readonly property OctagonShapeHelper shapeControl: OctagonShapeHelper {
        settings: root.settings
        target: root
    }

    containmentMask: shapeControl
    OctagonShape {
        id: shape
        shapeControl: root.shapeControl
        settings: shapeControl.settings
        width: root.width
        height: root.height
    }
}
