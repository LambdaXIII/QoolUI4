import QtQuick
import QtQuick.Templates as T

Item {
    id: root

    property Item target: T.Overlay.overlay
    property Item content

    // 替身契约的状态类属性开关（默认 false = 同步开启，使用方零影响）。
    // 开启后契约放弃对应属性的同步，content 回到 Qt 默认机制
    // （target 链 flow-on + 自身设置自由）——代价是父级对 root 的
    // 对应操作不再传递到 content（父级隐藏 Floater 时 content 若
    // 自己不处理则照常显示），content 可经声明链引用 root 自行响应。
    // 仅这两个属性有开关：其余属性（几何/层级/opacity）在 Qt 默认
    // 行为中本就独立，契约绑定即本体（见 docs/reference/Qool/Floater.md）。
    property bool noVisibleSync: false
    property bool noEnabledSync: false

    readonly property point globalPos: rootTracker.globalPos
    readonly property point floatingPos: pCtrl.floatingPos

    PositionTracker {
        id: rootTracker
        target: root
    }

    PositionTracker {
        id: targetTracker
        target: root.target
    }

    QtObject {
        id: pCtrl
        property point floatingPos
        function updatePos() {
            if (root.target)
                pCtrl.floatingPos = root.target.mapFromItem(root,
                                                            Qt.point(0, 0))
            else
                pCtrl.floatingPos = Qt.point(0, 0)
        }
    }

    // 位置重算由两个 tracker 的 scenePos 值变化驱动：root 链几何变化
    // 与 target 链几何变化都会使 floatingPos 失效（值去重——坐标实际
    // 未变时不触发）。target 属性变化经 targetTracker.target 绑定自动
    // 迁移（重配+重算）；root 被重父级经 rootTracker 自动重配；祖先链
    // 平移盲区由 tracker 的逐层监听覆盖。
    // 边界（与旧三组 Connections 行为一致，非回归）：target 自身
    // 变换（缩放/旋转围绕其原点）不改变 target 原点场景坐标——值去重
    // 后不触发重算，此时 content 位置不更新（契约外行为：追踪只对
    // 属性变化负责，见 PositionTracker 文档）。
    // 注意：Connections 默认启用（无需 enabled 门控）——tracker 首次
    // flush 经 singleShot(0) 落在事件循环批次，此时组件必已完成；
    // 组件完成前的初始位置由下方 Component.onCompleted 兜底。
    // （曾有误用 enabled: Component.completed——Component 无 completed
    // 属性，求值 undefined 导致 Connections 永久禁用、位置永不更新。）
    Connections {
        target: rootTracker
        function onScenePosChanged() {
            pCtrl.updatePos()
        }
    }
    Connections {
        target: targetTracker
        function onScenePosChanged() {
            pCtrl.updatePos()
        }
    }

    Binding {
        when: root.target && root.content
        root.content.parent: root.target
        root.content.width: root.width
        root.content.height: root.height
        root.content.x: pCtrl.floatingPos.x
        root.content.y: pCtrl.floatingPos.y
        root.content.z: root.z
        root.content.opacity: root.opacity
    }
    // visible/enabled 独立 Binding：受 noVisibleSync/noEnabledSync 开关
    // 控制（见属性注释）。拆分而非并入主 Binding——开关粒度只覆盖
    // 这两个状态类属性。
    Binding {
        when: root.target && root.content && !root.noVisibleSync
        root.content.visible: root.visible
    }
    Binding {
        when: root.target && root.content && !root.noEnabledSync
        root.content.enabled: root.enabled
    }

    implicitWidth: content?.implicitWidth ?? 100
    implicitHeight: content?.implicitHeight ?? 100

    Component.onCompleted: pCtrl.updatePos()
}
