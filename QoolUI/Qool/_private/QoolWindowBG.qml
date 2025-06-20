import QtQuick
import Qool

QoolBox {
    id: root

    anchors.fill: parent

    signal wannaMove(dx: real, dy: real)

    settings {
        cutSize: QoolConstants.windowCutSize
        borderColor: palette.accent
        fillColor: palette.window
        borderWidth: QoolConstants.windowBorderWidth
    }

    DragMoveArea {
        id: mArea
        target: null
        onWannaMove: (dx, dy) => root.wannaMove(dx, dy)
        containmentMask: root
    }
}
