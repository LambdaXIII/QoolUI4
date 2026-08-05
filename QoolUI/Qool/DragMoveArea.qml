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
        property point lastPoint: Qt.point(0, 0)
        property bool hovered: false
    }

    onEntered: pCtrl.hovered = true
    onExited: pCtrl.hovered = false

    onPressed: {
        pCtrl.startPoint = Qt.point(mouseX, mouseY);
        pCtrl.lastPoint = Qt.point(mouseX, mouseY);
        pCtrl.isMoving = true;
    }

    onPositionChanged: {
        if (pCtrl.isMoving) {
            // 增量语义（契约）：wannaMove 每次携带"相对上次位置"的偏移。
            // 消费方（autoBind 的 target.x += dx、QoolWindowBG/RectResizer
            // 的 width/height += dx）按增量叠加；若发"相对按下起点的累计
            // 位移"，每次 positionChanged 都重复累加 → 超量移动/跳变
            // （窗口拖动不跟手、RectResizer 变形夸张）。
            root.wannaMove(mouseX - pCtrl.lastPoint.x,
                           mouseY - pCtrl.lastPoint.y);
            pCtrl.lastPoint = Qt.point(mouseX, mouseY);
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
