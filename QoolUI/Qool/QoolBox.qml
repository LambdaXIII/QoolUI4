import QtQuick
import Qool

Item {
    id: root

    property OctagonSettings settings: OctagonSettings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: Style.accent
        fillColor: Style.dark
    }
    property alias shapeControl: shape.shapeControl

    property alias cutSize: root.settings.cutSize

    property alias fillItem: shape.fillItem

    OctagonShape {
        id: shape
        settings: root.settings
        width: root.width
        height: root.height
    }

    containmentMask: shape.shapeControl
}
