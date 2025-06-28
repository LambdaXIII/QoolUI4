import QtQuick
import Qool

SmartObject {
    id: root

    property real x
    property real y
    property real z
    property real width
    property real height
    property bool visible

    readonly property rect boundingRect: Qt.rect(x, y, width, height)
    function contains(p: point): bool {
        if (p.x < 0 || p.x > width || p.y < 0 || p.y > height)
            return false
        return true
    }
}
