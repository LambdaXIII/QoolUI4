import QtQuick

/*!
    \qmltype DragMoveArea
    \inqmlmodule Qool
    \brief 增量语义拖动区：拖动发出相对位移增量，可绑定移动任意目标。

    MouseArea 子类：按住拖动期间，每次鼠标位置变化发出
    \c wannaMove(offsetX, offsetY)——携带**相对上次位置的增量**。
    默认（\c autoBind 为 true）自动把增量叠加到 \c target 的位置；
    关闭 \c autoBind 后由消费方自行处理 \c wannaMove（如 RectResizer
    手柄按增量调整宿主尺寸）。

    \section1 增量基准

    \c wannaMove 的增量以**场景坐标**为基准（内部经 mapToItem(null)
    计算）——拖动中组件可能被外部移动（如 Floater 位置更新把 content
    拉回新位置、窗口拖动），局部坐标基准会被污染（增量 = 鼠标位移 −
    组件位移，走-停-走反复跳动、不跟手）。场景坐标是鼠标真实位置，
    与组件自身移动解耦。

    \section1 与系统拖动的配合

    实例可覆盖 \c onPressed 使用系统级拖动（如 QoolWindowBG 的
    startSystemMove/startSystemResize，Windows 下失败走 fallback
    增量路径）——内部拖动基准经 Connections 监听 \c pressedChanged
    建立，不受信号处理器覆盖影响。
*/

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

/*!
    \qmlproperty Item Qool::DragMoveArea::target
    \brief \c autoBind 开启时被移动的目标。默认 parent。
*/

/*!
    \qmlproperty bool Qool::DragMoveArea::autoBind
    \brief 拖动时自动把增量叠加到 \c target（默认 true）。关闭后只发
    \c wannaMove，由消费方处理（增量语义见类型文档）。
*/

/*!
    \qmlproperty bool Qool::DragMoveArea::hovered
    \brief 鼠标悬停状态（只读，自动更新）。
*/

/*!
    \qmlsignal Qool::DragMoveArea::wannaMove(real offsetX, real offsetY)
    \brief 拖动增量（相对上次位置；场景坐标基准，见类型文档）。
*/
