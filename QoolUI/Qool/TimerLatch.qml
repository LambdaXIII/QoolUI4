import QtQuick
import Qool

// TimerLatch：计时锁存器（Qool 模块通用逻辑件——与 PositionLocker 同族，
// 无控件依赖）。
//
// 语义：任何信号源经 `Connections { onXxx → latch.trigger() }` 触发——
// trigger() 立即锁存（active = true），经 interval 计时后自动释放
// （active = false）；窗口内重复触发重置计时（滑动窗口——持续触发持续保持）。
// 触发立即锁存、计时自动释放——区别于 SR latch 的手动复位（Timer 前缀 =
// 释放由计时驱动，避免"延迟地锁存"歧义）。
// 通用性：不依赖数值属性（与 NumberNotifier 无耦合）——"刚变化过"类反馈
// 的通用机制。
// 计时自持：内部内联 Timer（trigger 时 restart 重置、触发时释放）。

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
