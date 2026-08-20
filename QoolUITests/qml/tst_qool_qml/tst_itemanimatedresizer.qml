import QtQuick
import QtTest
import Qool

// ItemAnimatedResizer 行为测试（Qool/ItemAnimatedResizer.qml——resized
// 驱动的双向尺寸切换器，非可视组件）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认态：width/height = from 尺寸（100×100，收缩态）、resized=false、
//   running=false
// - 方向切换：resized=true → 前进到 to 尺寸（120×120）；false → 后退回
//   from——往返重复安全
// - 目标跟随：from/to 是绑定而非快照——就位后目标属性变化实时跟随
//   （锁定期 Binding 持续生效）
// - enabled 门控：false 时 resized 变化被忽略、尺寸冻结；恢复 true 后
//   再次 resized 变化才响应
// - 动画路径：animationEnabled=true 且方向模板 duration>0 → 动画过渡
//   （running 短暂为 true、尺寸中途值）；否则跳变
// - 方向模板独立：forewardAnimation/backwardAnimation 分别控制前进/后退
//   节奏（backward 模板不误用 foreward）
//
// 隔离策略：每个测试函数 createTemporaryObject 独立实例（状态隔离规范）；
// 时序/异步断言一律 tryCompare/tryVerify 轮询（不写固定 sleep）。
// 非动画测试显式 animationEnabled: false（父链回退 Style.animationEnabled
// 不可控）；动画测试单独开 true 并设短 duration。

TestCase {
    id: root

    name: "ItemAnimatedResizer"

    Component {
        id: resizerComp
        ItemAnimatedResizer {}
    }

    function makeResizer(extra) {
        const props = Object.assign({ animationEnabled: false }, extra)
        return createTemporaryObject(resizerComp, root, props)
    }

    function test_defaults() {
        // 默认态：收缩态（from 100×100）、未展开、未动画
        const r = makeResizer({})
        compare(r.resized, false)
        compare(r.width, 100)
        compare(r.height, 100)
        compare(r.running, false)
    }

    function test_advanceRetreat() {
        // 方向切换：true → to 尺寸、false → 回 from；往返重复安全
        const r = makeResizer({})
        r.resized = true
        compare(r.width, 120, "前进到 to 宽")
        compare(r.height, 120, "前进到 to 高")
        r.resized = false
        compare(r.width, 100, "后退回 from 宽")
        compare(r.height, 100, "后退回 from 高")
        // 往返一轮
        r.resized = true
        compare(r.width, 120)
        r.resized = false
        compare(r.width, 100)
    }

    function test_targetFollow() {
        // 目标跟随：from/to 是绑定而非快照——就位后目标变化实时跟随
        const r = makeResizer({})
        // 收缩态改 from → 跟随
        r.fromWidth = 150
        r.fromHeight = 60
        tryCompare(r, "width", 150, 1000, "from 宽变化跟随")
        tryCompare(r, "height", 60, 1000, "from 高变化跟随")
        // 展开态改 to → 跟随
        r.resized = true
        r.toWidth = 180
        r.toHeight = 90
        tryCompare(r, "width", 180, 1000, "to 宽变化跟随")
        tryCompare(r, "height", 90, 1000, "to 高变化跟随")
        // 切回收缩 → 新 from 生效
        r.resized = false
        tryCompare(r, "width", 150, 1000, "后退到新 from")
        tryCompare(r, "height", 60, 1000)
    }

    function test_disabledFreezes() {
        // enabled 门控：false 时 resized 变化被忽略、尺寸冻结；恢复后
        // 再次 resized 变化才响应
        const r = makeResizer({})
        r.enabled = false
        r.resized = true
        compare(r.width, 100, "禁用时前进被忽略")
        r.resized = false
        compare(r.width, 100, "禁用时后退无操作（冻结）")
        // 恢复 enabled：resized 变化重新响应（false → true 触发前进）
        r.enabled = true
        r.resized = true
        tryCompare(r, "width", 120, 1000, "恢复后 resized 变化响应")
    }

    function test_animationPath() {
        // 动画路径：animationEnabled=true + duration>0 → 动画过渡
        // （running 短暂为 true、到达 to 尺寸）
        const r = makeResizer({ animationEnabled: true })
        r.forewardAnimation.duration = 120
        r.backwardAnimation.duration = 120
        r.resized = true
        tryVerify(function () { return r.running }, 1000, "前进动画运行")
        tryCompare(r, "width", 120, 2000, "动画到达 to")
        tryCompare(r, "height", 120, 2000)
        r.resized = false
        tryVerify(function () { return r.running }, 1000, "后退动画运行")
        tryCompare(r, "width", 100, 2000, "动画回到 from")
        tryCompare(r, "height", 100, 2000)
    }

    function test_directionTemplatesIndependent() {
        // 方向模板独立：foreward 快、backward 慢——后退节奏取 backward
        // 模板（修复点：此前后退误用 foreward 模板时长）
        const r = makeResizer({ animationEnabled: true })
        r.forewardAnimation.duration = 10
        r.backwardAnimation.duration = 300
        r.resized = true
        tryCompare(r, "width", 120, 2000, "前进快（foreward 模板 10ms）")
        // 后退：300ms 动画进行中（150ms 窗口内）宽度应尚未到 from——
        // 若误用 foreward 模板（10ms）早已完成
        r.resized = false
        tryVerify(function () { return r.width > 100 }, 150,
            "后退进行中（backward 模板 300ms 生效）")
        tryCompare(r, "width", 100, 2000, "后退最终到达 from")
    }

    function test_zeroDurationJumps() {
        // duration=0 → 即使 animationEnabled=true 也跳变（无动画）
        const r = makeResizer({ animationEnabled: true })
        r.forewardAnimation.duration = 0
        r.backwardAnimation.duration = 0
        r.resized = true
        compare(r.width, 120, "duration=0 前进跳变")
        compare(r.running, false, "无动画运行")
        r.resized = false
        compare(r.width, 100, "duration=0 后退跳变")
        compare(r.running, false)
    }
}
