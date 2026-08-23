// CenterPlacer：中心坐标双向同步挂件（SmartObject——非 Item，无渲染）。
//
// 能力：把 target 的 x/y 与挂件自持的 centerx/centery 双向等价同步——
// 读写 center 即等价于读写 target 的左上角坐标（center = x + width/2）。
// 两套坐标系完整可用：消费方按场景自由选择（滑块用 x/y、二维表面用
// center）。
//
// 同步机制（防环设计，勿改成绑定）：
// - 读方向：onX/Y/W/HChanged → 写 centerx/centery（守卫：同值不写）。
// - 写方向：onCenterx/CenteryChanged → 写 target.x/y（同值守卫断环——
//   target 写回同值时其 Changed 不触发，环断开）。
// - w/h 参与换算（center = x + w/2）——根尺寸变化中心随之变。
// - 初始同步：Connections 只响应「变化」，target 声明时已带值则 center
//   不会自举——完成时从 target 现读一次，创建即双向等价。
// - target 为 null 安全：读写方向均有守卫，不崩不写。
// - target 切换（开放接口）：运行中换挂载对象 → 从新 target 现读同步
//   （旧 center 不残留）；Connections 的 target 绑定自动转移。
// 与旧 ColorCursor 双同步环的区别：本件纯 Connections 程序化、守卫统一
// 覆盖双向、无绑定互指——环被同值守卫 + 单向写回方向彻底断开。
//
// 封装（对齐 ItemAnimatedResizer 的 pCtrl 模式）：
// - 同步函数收进内部 pCtrl（id 文件作用域——外部实例不可访问，不暴露
//   内部方法）；对外仅 target/centerx/centery 三个属性。
// - 自身信号监听一律用 Connections 独立对象（非 onXxxChanged 直接
//   handler）——后者可被外部实例的同名 handler 覆盖（QML 信号处理器
//   后写覆盖先写），Connections 独立监听不受影响。
//
// 绑定用法注意：消费方若用 QML 绑定将 centerx/centery 连到 position(...)
// 映射，onXChanged 显式回写会替换该绑定（QML 显式赋值破坏绑定）——建议
// 事件驱动赋值或保证 target.x 仅由 center 驱动（守卫断环使绑定安全）。

import QtQuick
import Qool

SmartObject {
    id: root

    // 任意带 x/y/width/height 四个属性的对象（Item/QtObject 自定义属性
    // 均可）。null 时安全（不崩、不写）。开放接口——可随时切换。
    property QtObject target: parent

    // 中心坐标（挂件自持属性——QML 无法给 target 动态加属性，center 由
    // 挂件持有，内部同步到 target）。读写即等价于读写 target 的 x/y。
    property real centerx
    property real centery

    // —— 内部实现载体：同步函数（外部不可访问）——
    QtObject {
        id: pCtrl

        function sync_x() {
            const v = root.target.x + root.target.width / 2;
            if (root.centerx !== v)
                root.centerx = v;
        }

        function sync_y() {
            const v = root.target.y + root.target.height / 2;
            if (root.centery !== v)
                root.centery = v;
        }

        // 从当前 target 现读同步（初始与 target 切换共用）——Connections
        // 只响应「变化」：target 声明时已带值、或运行中换了 target，center
        // 都不会自举，需显式现读一次，保证「挂上即双向等价」。
        function resync() {
            if (!root.target)
                return;
            sync_x();
            sync_y();
        }

        function write_x() {
            if (!root.target)
                return;
            const v = root.centerx - root.target.width / 2;
            if (root.target.x !== v)
                root.target.x = v;
        }

        function write_y() {
            if (!root.target)
                return;
            const v = root.centery - root.target.height / 2;
            if (root.target.y !== v)
                root.target.y = v;
        }
    }

    // —— 读方向：target 几何变化 → 更新 center（守卫：同值不写）——
    Connections {
        target: root.target
        function onXChanged() {
            pCtrl.sync_x();
        }
        function onYChanged() {
            pCtrl.sync_y();
        }
        function onWidthChanged() {
            pCtrl.sync_x();
        }
        function onHeightChanged() {
            pCtrl.sync_y();
        }
    }

    // —— 写方向：center 变化 → 写 target.x/y（同值守卫断环）——
    // Connections 独立对象——外部实例的 onCenterxChanged handler 不覆盖
    // 此监听（多监听者共存）。
    Connections {
        target: root
        function onCenterxChanged() {
            pCtrl.write_x();
        }
        function onCenteryChanged() {
            pCtrl.write_y();
        }
    }

    // —— target 切换（开放接口）：Connections 而非 onTargetChanged 直接
    // handler——后者可被外部实例覆盖；Connections 独立监听不受影响。
    // 切换即从新 target 现读同步 center（单一事实源 = target；旧 center
    // 不残留）。读方向 Connections 的 target 绑定自动断开旧对象、连接
    // 新对象。
    Connections {
        target: root
        function onTargetChanged() {
            pCtrl.resync();
        }
    }

    // 初始同步：Connections 只响应「变化」，target 声明时已带值（x/y 默认
    // 0 无变化信号）则 center 不会自举——完成时从 target 现读一次，保证
    // 创建即双向等价（读写 center ≡ 读写 x/y 的完整契约）。
    Component.onCompleted: {
        pCtrl.resync();
    }
}
