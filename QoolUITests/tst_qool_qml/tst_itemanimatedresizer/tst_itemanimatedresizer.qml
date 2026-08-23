import QtQuick
import QtTest
import Qool

// ItemAnimatedResizer 行为测试（Qool/ItemAnimatedResizer.qml——resized
// 驱动的双向尺寸切换器，非可视组件）
//
// 被测契约（外部行为与公开契约——不测内部实现）：
// - 默认态：width/height = from 尺寸（100×100，收缩态）、resized=false、
//   running=false
// - 初始就位：构造时 resized 已绑定为 true → 跳变就位到 to 尺寸、无动画
//   （修复点：此前仅 onResizedChanged 触发 ensure，初始绑定求值不触发，
//   初始 resized=true 停在收缩态）
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

    function test_initialResizedTrue() {
        // 初始 resized=true（构造即绑定）：跳变就位到 to 尺寸（修复点——
        // 此前仅 onResizedChanged 触发 ensure，初始绑定求值不触发，初始
        // resized=true 停在收缩态，违反「resized 是方向开关」契约）
        const r = makeResizer({ resized: true })
        compare(r.resized, true)
        compare(r.width, 120, "初始 resized=true 就位到 to 宽")
        compare(r.height, 120, "初始 resized=true 就位到 to 高")
        compare(r.running, false)
    }

    function test_initialSettleNoAnimation() {
        // 初始就位跳变、不经动画（修复点 2：ensure 的动画路径仅用于状态
        // 变化过渡——初始化不该有动画，即使 animationEnabled=true 且
        // duration>0）
        const r = makeResizer({ animationEnabled: true, resized: true })
        r.forewardAnimation.duration = 300
        r.backwardAnimation.duration = 300
        compare(r.width, 120, "初始就位直接到 to 宽（无动画）")
        compare(r.height, 120, "初始就位直接到 to 高（无动画）")
        compare(r.running, false, "初始就位无动画运行")
        // 之后正常 resized 变化仍走动画路径
        r.resized = false
        tryVerify(function () { return r.running }, 1000, "后续变化走动画")
        tryCompare(r, "width", 100, 2000, "动画回到 from")
    }

    function test_initialResizedFalseFreezesWhenDisabled() {
        // 初始 enabled=false：冻结契约——构造不就位（与响应门控一致）
        const r = makeResizer({ enabled: false, resized: true })
        compare(r.width, 100, "禁用时构造不就位（冻结）")
        // 恢复 enabled 后 resized 变化才响应
        r.enabled = true
        r.resized = false
        r.resized = true
        tryCompare(r, "width", 120, 1000, "恢复后 resized 变化响应")
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


    function test_enabledRestoreResyncs() {
        // enabled 恢复就位（开放接口修复点）：禁用期间 resized 变化被
        // 忽略、尺寸冻结；恢复 enabled 时 resized 已处于目标值、不再有
        // 变化信号 → 恢复即按当前 resized 就位（非等待下一次变化）
        const r = makeResizer({})
        r.enabled = false
        r.resized = true          // 被忽略（冻结在收缩态）
        compare(r.width, 100, "禁用时前进被忽略")
        // 恢复 enabled：resized 已 true 且无变化信号 → 应就位到 to
        r.enabled = true
        tryCompare(r, "width", 120, 1000, "恢复 enabled 即就位到 to")
        compare(r.height, 120, "恢复即就位到 to 高")
    }

    function test_enabledRestoreSettlesNoChange() {
        // 恢复 enabled 时 resized 未变（仍 false 收缩态）：就位 no-op
        // （不闪动、尺寸不动）
        const r = makeResizer({})
        r.enabled = false
        r.enabled = true
        compare(r.width, 100, "恢复后收缩态保持（no-op）")
        compare(r.running, false, "无动画")
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
