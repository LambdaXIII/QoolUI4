import QtQuick
import Qool

// TimerLatch：计时锁存器（Qool 模块通用逻辑件——与 PositionLocker 同族，
// 无控件依赖）。
//
// 语义：任何信号源经 `Connections { onXxx → latch.trigger() }` 触发——
// trigger() 立即锁存（active = true），经 interval 计时后自动释放
// （active = false）；窗口内重复触发重置计时（滑动窗口——持续触发持续保持）。
// 触发立即锁存、计时自动释放——区别于 SR latch 的手动复位（"延迟锁存器"
// 命名辩论定案：Timer 前缀 = 释放由计时驱动，避免"延迟地锁存"歧义）。
// 通用性：不依赖数值属性（与 NumberNotifier 无耦合）——"刚变化过"类反馈
// 的通用机制（v3 movementTimer/justMoved 模式的系统化替代）。
// 计时自持：内部内联 Timer（trigger 时 restart 重置、触发时释放）——
// 不依赖 DelayTimer（后者已删除，滚动指示器淡出等用途改由本组件承担）。

/*!
    \qmltype TimerLatch
    \inqmlmodule Qool
    \brief 计时锁存器：触发即锁存、计时自动释放的滑动窗口状态。

    \c trigger() 立即置 \c active 为 true 并重置计时；经 \c interval（默认
    1000ms）无再次触发后自动释放（active = false）。窗口内重复触发重置
    计时——持续触发持续保持（滑动窗口）。\c active 为声明式状态，可直接
    绑定（如透明度/展开态）；\l activated / \l deactivated 为窗口边界事件。

    任意信号源可触发（如 \c{Connections { onXxx → latch.trigger() }}）——
    通用"刚变化过"类反馈机制（v3 movementTimer/justMoved 模式的系统化
    替代：Slider 手柄展开窗口、滚动指示器淡出延迟均基于本件）。

    与 SR latch 的差异：释放由计时驱动（非手动复位）。仅需"延迟后执行
    一次"的宿主请用裸 \l Timer。
*/

SmartObject {
    id: root

    property int interval: 1000
    readonly property bool active: pCtrl.active

    signal activated
    signal deactivated

    QtObject {
        id: pCtrl
        property bool active: false
        onActiveChanged: {
            if (active)
                root.activated();
            else
                root.deactivated();
        }
    }

    Timer {
        id: delayTimer
        interval: root.interval
        onTriggered: pCtrl.active = false
    }

    function trigger() {
        pCtrl.active = true;
        delayTimer.restart();
    }
}
