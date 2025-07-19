import QtQuick
import Qool

Item {
    id: root
    property QoolBoxSettings settings: QoolBoxSettings {
        borderWidth: 10
    }
    readonly property QoolBoxShapeControl control: QoolBoxShapeControl {
        settings: root.settings
        target: root
    }

    property Item fillItem: null

    Rectangle {
        topLeftRadius: root.control.settings.cutSizeTL
        topRightRadius: root.control.settings.cutSizeTR
        bottomLeftRadius: root.control.settings.cutSizeBL
        bottomRightRadius: root.control.settings.cutSizeBR
        color: root.control.settings.fillColor
        border.color: root.control.settings.borderColor
        border.width: root.control.settings.borderWidth
        width: root.control.width
        height: root.control.height
        x: root.control.settings.offsetX
        y: root.control.settings.offsetY
    }
}
