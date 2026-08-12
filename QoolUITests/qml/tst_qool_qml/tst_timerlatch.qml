import QtQuick
import QtTest
import Qool

// TimerLatch 行为测试（Qool/TimerLatch.qml）
//
// 被测契约：
// - 初始状态 active == false、interval 默认 1000
// - trigger() 立即锁存（active = true）并发出 activated
// - 窗口内重复触发重置计时（滑动窗口），重复触发不重复发出 activated
// - interval 计时结束自动释放（active = false）并发出 deactivated
// - 释放后可再次触发（activated 再次发出）
//
// 隔离策略（重要）：TestCase 的各测试函数共享同一实例且按函数名顺序执行，
// 共享实例会让 interval/active 状态跨测试泄漏。因此每个测试函数用
// createTemporaryObject 创建独立 TimerLatch 实例（测试结束自动销毁），
// SignalSpy 动态创建——这是 Qt Quick Test 的状态隔离最佳实践。

TestCase {
    id: root

    name: "TimerLatch"

    Component {
        id: timerLatchComp
        TimerLatch {}
    }

    function makeLatch() {
        return createTemporaryObject(timerLatchComp, root)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject("import QtTest; SignalSpy {}", root)
        spy.target = target
        spy.signalName = signalName
        return spy
    }

    function test_initialState() {
        const latch = makeLatch()
        compare(latch.active, false)
        compare(latch.interval, 1000)
    }

    function test_triggerActivatesImmediately() {
        const latch = makeLatch()
        const activatedSpy = makeSpy(latch, "activated")
        const deactivatedSpy = makeSpy(latch, "deactivated")

        latch.trigger()
        compare(latch.active, true)
        compare(activatedSpy.count, 1)
        compare(deactivatedSpy.count, 0)
    }

    function test_autoReleaseAfterInterval() {
        const latch = makeLatch()
        const activatedSpy = makeSpy(latch, "activated")
        const deactivatedSpy = makeSpy(latch, "deactivated")

        latch.interval = 50
        latch.trigger()
        verify(latch.active)
        compare(deactivatedSpy.count, 0) // 计时中尚未释放
        tryCompare(deactivatedSpy, "count", 1, 2000) // 等待释放
        compare(latch.active, false)
        compare(activatedSpy.count, 1)
    }

    function test_slidingWindowKeepsActive() {
        const latch = makeLatch()
        const activatedSpy = makeSpy(latch, "activated")
        const deactivatedSpy = makeSpy(latch, "deactivated")

        latch.interval = 100
        latch.trigger()
        latch.trigger() // 窗口内重复触发：重置计时
        latch.trigger()
        verify(latch.active)
        compare(activatedSpy.count, 1) // 重复触发不重发 activated
        // 最后一次触发后再过 interval 才释放
        tryCompare(deactivatedSpy, "count", 1, 3000)
        compare(latch.active, false)
        compare(deactivatedSpy.count, 1)
    }

    function test_retriggerAfterRelease() {
        const latch = makeLatch()
        const activatedSpy = makeSpy(latch, "activated")
        const deactivatedSpy = makeSpy(latch, "deactivated")

        latch.interval = 30
        latch.trigger()
        tryCompare(deactivatedSpy, "count", 1, 2000)
        compare(latch.active, false)

        // 释放后可再次激活
        latch.trigger()
        compare(latch.active, true)
        compare(activatedSpy.count, 2)
    }

    function test_intervalPropertyWritable() {
        const latch = makeLatch()
        latch.interval = 250
        compare(latch.interval, 250)
        latch.interval = 1000
        compare(latch.interval, 1000)
    }
}
