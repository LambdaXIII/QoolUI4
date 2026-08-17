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

    // 基准初始化走 Connections（监听 pressedChanged）而非 onPressed
    // 处理器：使用处可覆盖 onPressed（如 QoolWindowBG 的
    // startSystemMove 系统拖动——Windows 下失败走 fallback 增量路径），
    // 覆盖后内部 onPressed 不执行、基准缺失 → fallback 失效；Connections
    // 独立监听信号，不受处理器覆盖影响，两条路径都建立基准。
    Connections {
        target: root
        function onPressedChanged() {
            if (root.pressed && !pCtrl.isMoving) {
                // 基准用场景坐标（mapToItem(null) = 场景坐标系）：本组件
                // 可能被外部移动（Floater 位置更新把 content 拉回新位置、
                // 窗口拖动），局部坐标基准会受污染。
                const sp = root.mapToItem(null, root.mouseX, root.mouseY)
                pCtrl.startPoint = sp
                pCtrl.lastPoint = sp
                pCtrl.isMoving = true
            } else if (!root.pressed && pCtrl.isMoving) {
                pCtrl.isMoving = false
            }
        }
    }

    onPositionChanged: {
        if (pCtrl.isMoving) {
            // 增量语义（契约）：wannaMove 每次携带"相对上次位置"的偏移。
            // 消费方（autoBind 的 target.x += dx、QoolWindowBG/RectResizer
            // 的 width/height += dx）按增量叠加；若发"相对按下起点的累计
            // 位移"，每次 positionChanged 都重复累加 → 超量移动/跳变
            // （窗口拖动不跟手、RectResizer 变形夸张）。
            // 基准必须用场景坐标（mapToItem(null)）：本组件被外部移动时
            // （Floater 位置更新把 content 拉回新位置），局部坐标 mouseX
            // 反向变化——增量 = 鼠标位移 - 本组件位移（dₙ = mₙ − dₙ₋₁，
            // 走-停-走反复跳动、不跟手）；场景坐标是鼠标真实位置，
            // 与组件自身移动解耦。
            const cur = root.mapToItem(null, mouseX, mouseY)
            root.wannaMove(cur.x - pCtrl.lastPoint.x,
                           cur.y - pCtrl.lastPoint.y)
            pCtrl.lastPoint = cur
        }
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
