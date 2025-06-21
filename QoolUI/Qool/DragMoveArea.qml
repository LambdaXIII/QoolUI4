import QtQuick

MouseArea {
    id: root

    property Item target: parent
    property bool autoBind: true

    readonly property bool hovered: pCtrl.hovered

    acceptedButtons: Qt.LeftButton

    signal wannaMove(real offsetX, real offsetY)

    QtObject {
        id: pCtrl
        property bool isMoving: false
        property point startPoint: Qt.point(0, 0)
        property bool hovered: false
    }

    onEntered: pCtrl.hovered = true
    onExited: pCtrl.hovered = false

    onPressed: {
        pCtrl.startPoint = Qt.point(mouseX, mouseY);
        pCtrl.isMoving = true;
    }

    onPositionChanged: {
        if (pCtrl.isMoving) {
            root.wannaMove(mouseX - pCtrl.startPoint.x, mouseY - pCtrl.startPoint.y);
        }
    }

    onReleased: {
        pCtrl.isMoving = false;
    }

    Connections {
        enabled: root.enabled && root.target && root.autoBind
        function onWannaMove(dx, dy) {
            if (dx !== 0) {
                const x = root.target.x + dx;
                root.target.x = x;
            }
            if (dy !== 0) {
                const y = root.target.y + dy;
                root.target.y = y;
            }
        }
    }//connections
}
