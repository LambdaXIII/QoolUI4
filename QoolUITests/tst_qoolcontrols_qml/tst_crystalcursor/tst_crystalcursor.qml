import QtQuick
import QtTest
import Qool
import Qool.Controls.Components

// CrystalCursor 行为测试（Qool.Controls.Components/CrystalCursor.qml）
//
// 被测契约（docs/reference/Qool.Controls.Components/CrystalCursor.md 为准绳）：
// - 默认 expanded=true → 展开态自洽（独立使用即展开）
// - expanded=false → 经 delay 窗口后收缩到 fullSize − delta
// - delay 窗口：expanded 变化经锁存窗口落定（防抖——窗口内保持、窗口后
//   随 expanded 回落）；不监听值信号（无 latchTarget 接口）
// - delta 控制缩放增量（常态 = fullSize − delta、展开 = fullSize）
// - 色外包：color/borderColor 属性传递（默认绑 Style）
// - 契约裁剪：无 defaultValue/reset 属性
// - readonly fullSize = min(根 w,h)、size = 内部 Crystal 当前边长
// - 长方形根：菱形内切 min 边居中（fullSize = 短边）
// - 根 footprint 恒定：根尺寸不随缩放变化（定位锚稳定）
//
// 隔离策略：每测试函数独立实例；动画统一关闭（Style.animationEnabled: false——
// 尺寸跳变即时）；delay 设小值加速窗口落定。
// 命中域（菱形 contains）不经鼠标事件自动化（offscreen 不注入合成事件）——
// Crystal 自身掩码契约由 tst_crystal 覆盖。

TestCase {
    id: root

    name: "CrystalCursor"
    width: 300
    height: 300

    Component {
        id: cursorComp
        CrystalCursor {
            width: 40
            height: 40
            Style.animationEnabled: false
            delay: 20
            delta: 10
        }
    }

    function makeCursor(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(cursorComp, root, props)
    }

    // —— 默认 expanded=true：展开态自洽 ——
    function test_defaultExpanded() {
        const c = makeCursor({})
        compare(c.expanded, true, "expanded defaults true")
        compare(c.fullSize, 40, "fullSize = min(w,h)")
        compare(c.size, 40, "default expanded -> size = fullSize")
    }

    // —— expanded=false → 收缩到 fullSize − delta ——
    function test_contract() {
        const c = makeCursor({})
        c.expanded = false
        // 经 delay 窗口落定（动画关 → 即时跳变；latch 窗口后收缩）
        tryCompare(c, "size", 40 - 10, 2000)
        compare(c.size, 30, "resting = fullSize − delta")
    }

    // —— delay 窗口：变化经锁存窗口落定（防抖——窗口内保持）——
    function test_delayWindow() {
        const c = makeCursor({ delay: 100 })
        c.expanded = false
        // 窗口内（latch 保持展开）——防抖：快速状态变化不闪缩
        compare(c.size, 40, "within delay window stays expanded")
        // 窗口后随 expanded 回落
        tryCompare(c, "size", 30, 2000)
    }

    // —— delta 控制缩放增量 ——
    function test_deltaScaling() {
        const c = makeCursor({ delta: 4 })
        c.expanded = false
        tryCompare(c, "size", 40 - 4, 2000)
        const d = makeCursor({ delta: 20 })
        d.expanded = false
        tryCompare(d, "size", 40 - 20, 2000)
    }

    // —— 色外包：color/borderColor 属性传递（默认绑 Style）——
    function test_colorOutsourcing() {
        const c = makeCursor({})
        compare(c.color, c.Style.accent, "default color = Style.accent")
        compare(c.borderColor, ThemeHQ.recommendForeground(c.Style.accent),
                "default borderColor = recommend(color)")
        c.color = "#ff8800"
        compare(c.borderColor, ThemeHQ.recommendForeground("#ff8800"),
                "borderColor follows color")
        c.borderColor = "#123456"
        compare(c.borderColor, "#123456", "borderColor directly settable")
    }

    // —— 契约裁剪：无 defaultValue/reset ——
    function test_noResetContract() {
        const c = makeCursor({})
        verify(c.defaultValue === undefined, "no defaultValue property")
        verify(c.reset === undefined, "no reset property")
    }

    // —— readonly fullSize/size ——
    function test_readonlyGeom() {
        const c = makeCursor({})
        c.width = 60
        c.height = 60
        compare(c.fullSize, 60, "fullSize follows min(w,h)")
        compare(c.size, 60, "size follows fullSize when expanded")
        c.expanded = false
        tryCompare(c, "size", 60 - 10, 2000)
    }

    // —— 长方形根：菱形内切 min 边居中 ——
    function test_rectangularRoot() {
        const c = makeCursor({ width: 60, height: 40 })
        compare(c.fullSize, 40, "rect root fullSize = short edge")
        compare(c.size, 40, "diamond inscribes short edge")
        compare(c.width, 60, "root keeps rectangular footprint")
        compare(c.height, 40)
    }

    // —— 根 footprint 恒定：缩放不改变根尺寸（定位锚稳定）——
    function test_rootFootprintConstant() {
        const c = makeCursor({})
        c.expanded = false
        tryCompare(c, "size", 30, 2000)
        compare(c.width, 40, "root width unchanged by scale")
        compare(c.height, 40, "root height unchanged by scale")
    }

    // —— 不监听值信号：无 latchTarget 接口 ——
    function test_noLatchTarget() {
        const c = makeCursor({})
        verify(c.latchTarget === undefined, "no latchTarget (no value-signal listening)")
    }
}
