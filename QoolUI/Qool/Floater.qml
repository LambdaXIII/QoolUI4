import QtQuick
import QtQuick.Templates as T

/*!
    \qmltype Floater
    \inqmlmodule Qool
    \brief 简化弹层：内容渲染在 target（默认 Overlay），声明几何在父坐标系。

    Floater 是简化版 Popup：不做模态/焦点/dismiss/过渡，只保证「位置正确」。
    从宿主视角，Floater 是 \c content 的替身（proxy）——content 渲染在
    \c target 下，但几何/层级/透明度/可见性/可用性经替身契约从本组件全量
    同步：父级对本组件的观察与操作都会传递到 content，content 对父级透明、
    不可直接操作。

    继承自 Item，Item 的全部 API 可用。

    \section1 位置

    content 的位置 = 本组件左上角在 target 坐标系中的位置（场景坐标通道，
    不依赖窗口位置）。祖先链任意层平移/缩放/旋转自动触发重算
    （PositionTracker 驱动）；\c transform 列表变化无信号，可调用
    \c refresh() 强制刷新。content 的尺寸/透明度等随本组件同步。

    \section1 层级（z）

    多个 Floater 使用同一 target 时，声明处的 \c z 即 target 内层级——
    这是宿主控制同 target 层序消歧的唯一手段。

    \section1 可见性与可用性

    父链显式隐藏时经 Qt flow-on 自动传递（本组件 visible 值变化 →
    content 跟随）；target 链的隐藏/禁用直接作用于 content 渲染层，
    不反映到本组件属性值。content 根对象的 visible/enabled 由替身契约
    驱动——浮层显隐的常规做法是控制本组件的 \c visible 或 \c opacity
    （QoolTip 即用 opacity）；需要 content 自行判断时用 \c noVisibleSync
    开关。

    \section1 事件

    content 的命中/事件走 target 链（Overlay），不经替身——父级在本组件
    上方叠 MouseArea 拦不到 content。这是期望行为（装饰不被宿主遮挡）。

    \section1 开关

    \c noVisibleSync / \c noEnabledSync 开启后，契约放弃对应属性的同步，
    content 回到 Qt 默认机制（可自行绑定/显式设置）。代价：父级对本组件
    对应属性的操作不再传递到 content——父级隐藏 Floater 时 content 若
    自己不处理则照常显示（content 可经声明链引用本组件自行响应）。

    \section1 信号

    本类型不新增信号；属性变化经 Qt 自动生成的 \c xxxChanged 信号通知
    （如 \c noVisibleSyncChanged / \c noEnabledSyncChanged）。

    \section1 其他

    运行期替换 \c content 时旧对象留在 target 下（parent 不还原、几何
    冻结）——宿主自行善后。透明度同步为值同步：本组件祖先链 opacity≠1
    时 content 的有效透明度可能与本组件不一致（值同步即契约，期望行为）。
*/

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
    // 行为中本就独立，契约绑定即本体（见 QDoc）。
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
    // 平移盲区由 tracker 的逐层监听覆盖——不再需要宿主手动 refresh
    // 补偿（RectResizer 旧用法保留，refresh 仍可用）。
    // 边界（与旧三组 Connections 行为一致，非回归）：target 自身
    // 变换（缩放/旋转围绕其原点）不改变 target 原点场景坐标——不触发
    // 重算；此时 content 位置由 refresh() 强制刷新兜底。
    Connections {
        target: rootTracker
        enabled: Component.completed
        function onScenePosChanged() {
            pCtrl.updatePos()
        }
    }
    Connections {
        target: targetTracker
        enabled: Component.completed
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

    // 公开刷新入口：先强制两个 tracker 立即重算（覆盖无信号盲区，
    // 如 transform 列表变化），再直接重算位置——tracker 重算后若
    // scenePos 未变不会发信号，必须显式 updatePos。
    function refresh() {
        rootTracker.update()
        targetTracker.update()
        pCtrl.updatePos()
    }

    Component.onCompleted: pCtrl.updatePos()
}

/*!
    \qmlproperty Item Qool::Floater::target
    \brief content 的渲染父级。默认 T.Overlay.overlay，可为任意 item 层。
    运行时切换自动生效（tracker 随绑定迁移、坐标自动重算）。
*/

/*!
    \qmlproperty Item Qool::Floater::content
    \brief 浮层内容（声明为本组件属性值）。渲染在 \c target 下，
    几何与状态属性由替身契约接管。
*/

/*!
    \qmlproperty point Qool::Floater::globalPos
    \brief 本组件左上角的屏幕坐标（只读，自动更新）。
*/

/*!
    \qmlproperty point Qool::Floater::floatingPos
    \brief content 在 target 坐标系中的位置（只读，自动更新）。
*/

/*!
    \qmlproperty bool Qool::Floater::noVisibleSync
    \brief 关闭 visible 同步（默认 false）。见类型文档「开关」节。
*/

/*!
    \qmlproperty bool Qool::Floater::noEnabledSync
    \brief 关闭 enabled 同步（默认 false）。见类型文档「开关」节。
*/

/*!
    \qmlmethod void Qool::Floater::refresh()
    \brief 强制刷新位置计算。覆盖无信号盲区（如 transform 列表变化）。
*/
