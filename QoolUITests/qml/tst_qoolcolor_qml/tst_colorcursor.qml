import QtQuick
import QtTest
import Qool
import Qool.Color
import "qrc:/qt/qml/Qool/Color/_private"

// ColorCursor 测试（Qool.Color/_private/ColorCursor.qml——HSV/HSL 两表面
// 共用的组合取色光标：CrystalCursor + CenterPlacer + 值变化锁存）。
//
// 被测契约（docs/reference/Qool.Color/ColorCursor.md 为准绳，逐条对应）：
// - centerx/centery 与 x/y 双向等价（经 CenterPlacer：写 center → 代理设
//   x/y；写 x/y → center 跟随；center = x + width/2）
// - 视觉语义：常态 Crystal 边长 = size、展开 = size + expandDelta
//   （内部基准件 fullSize = size + expandDelta、delta = expandDelta）
// - 三态展开：userInteracting / hover / 值变化锁存任一 → expanded
//   （本测试覆盖 userInteracting 与值变化锁存两路——hover 不经合成事件
//   注入，人工运行验证）
// - 实色透传：currentColor → 内部 CrystalCursor.color
// - 契约裁剪：无 defaultValue/reset（双击无定义行为）
//
// 隔离：每个测试函数独立场景；动画统一关闭（animationEnabled: false——
// 断言不等动画，与 tst_hsvwheel 同策略）。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "ColorCursor"
    width: 400
    height: 400

    Component {
        id: cursorComp
        Item {
            width: 400
            height: 400

            property alias cursorRef: cursor

            ColorCursor {
                id: cursor
                animationEnabled: false
            }
        }
    }

    function makeCursor() {
        return createTemporaryObject(cursorComp, root, {}).cursorRef
    }

    // 内部基准件定位（objectName 定位——组件内部对象零暴露原则的测试
    // 例外：tst_hsvwheel 同款 findChild 递归实现）
    function findChild(item, name) {
        if (item === null || item === undefined)
            return null
        for (let i = 0; i < item.children.length; ++i) {
            if (item.children[i].objectName === name)
                return item.children[i]
        }
        for (let i = 0; i < item.children.length; ++i) {
            const hit = findChild(item.children[i], name)
            if (hit !== null)
                return hit
        }
        if (item.item !== undefined && item.item !== null) {
            const hit = findChild(item.item, name)
            if (hit !== null)
                return hit
        }
        return null
    }

    function baseOf(c) {
        return findChild(c, "baseCursor")
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 双向等价：center ↔ x/y（经 CenterPlacer）——
    function test_centerPositioning() {
        const c = makeCursor()
        // 默认 size=20 → 根 20×20；写 center → x = center − width/2
        c.centerx = 50
        tryCompare(c, "x", 40, 1000)
        c.centery = 80
        tryCompare(c, "y", 70, 1000)
        // 反向：写 x/y → center 跟随
        c.x = 100
        tryCompare(c, "centerx", 110, 1000)
        c.y = 60
        tryCompare(c, "centery", 70, 1000)
        // 双向等价：center 读 = x + width/2（往返稳定）
        verify(fuzzy(c.centerx, 110), "centerx reads x + width/2")
        verify(fuzzy(c.centery, 70), "centery reads y + height/2")
    }

    // —— 视觉语义：userInteracting 展开 / 释放收缩 + fullSize 组合 ——
    function test_expansion() {
        const c = makeCursor()
        const base = baseOf(c)
        verify(base !== null, "base cursor exists")
        // 组合语义：基准件 fullSize = size + expandDelta（fuzzy——浮点）
        verify(fuzzy(base.fullSize, c.size + c.expandDelta),
               "base fullSize = size + expandDelta")
        // 常态：size = size（20）——创建后锁存窗口已过（无 center 变化）
        c.centerx = 40  // 触发一次锁存，先让其稳定
        c.centery = 40
        wait(600)
        tryCompare(base, "size", c.size, 1000)
        // 展开：userInteracting → 立即展开到 fullSize（animationEnabled
        // false → 即时跳变，无动画等待）
        c.userInteracting = true
        tryCompare(base, "size", base.fullSize, 1000)
        // 收缩：释放 → 经 delay 窗口回落（CrystalCursor 默认 delay 150ms，
        // 超时给 1000ms 覆盖）
        c.userInteracting = false
        tryCompare(base, "size", c.size, 1000)
    }

    // —— 值变化锁存：center 变化触发展开、锁存窗口过后回落 ——
    function test_valueChangeLatch() {
        const c = makeCursor()
        const base = baseOf(c)
        verify(base !== null, "base cursor exists")
        // 创建瞬间 CenterPlacer 初始 resync 触发一次锁存——等待稳定
        wait(600)
        tryCompare(base, "size", c.size, 1000)
        // 写 center → 锁存展开（值变化 = 位置变化 = 表面值变化）
        c.centerx = 120
        tryCompare(base, "size", base.fullSize, 1000)
        // 锁存窗口（Style.movementDuration * 2）过后回落收缩
        wait(1000)
        tryCompare(base, "size", c.size, 1000)
    }

    // —— 实色透传：currentColor → 内部 CrystalCursor.color ——
    function test_solidColor() {
        const c = makeCursor()
        const base = baseOf(c)
        verify(base !== null, "base cursor exists")
        c.currentColor = "#123456"
        tryCompare(base, "color", "#123456")
    }

    // —— 契约裁剪：无 defaultValue/reset ——
    function test_noReset() {
        const c = makeCursor()
        verify(c.reset === undefined, "no reset function")
        verify(c.defaultValue === undefined, "no defaultValue property")
    }
}
