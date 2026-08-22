import QtQuick
import QtTest
import Qool
import Qool.Color

// HSVWheel 测试（Qool.Color/HSVWheel.qml——v4 公开 HSV 二维取色表面：单向链
// 架构 + 三值双向接口 + 写入钳制两路 + 光标数据派生定位 + value 驱动圆盘）。
//
// 被测契约（外部行为与公开契约——spec.md 为准绳，逐条对应）：
// - 三值双向同步：写 hue/saturation/value → assistant 对应通道；assistant
//   变 → 回读；同值写入不循环（assistant 相等守卫收敛）
// - onCompleted 播种：assistant 预设色 → hue/sat/value 回读（越界 hue 不播种）
// - hue 越界（<0 无色相）接口写入不写进 assistant、显示保持
// - 钳制：sat/value/hue>1 clamp 收敛（接口属性与 assistant 都收敛到合法域）
// - value 驱动圆盘压暗层（darkAlpha = 1 - value 派生契约）
// - 光标定位派生：position(hue,sat) 输出有效（值合法 → 光标恒在圆内）
// - 无 defaultValue/reset、双击无定义行为（交互契约裁剪）
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 真实鼠标交互（拖动/圆外点击）不在自动化范围（offscreen 不注入合成事件，
// 与 tst_colorchannelslider 同策略）——交互映射以几何断言 + 人工运行验证
// 覆盖。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "HSVWheel"
    width: 400
    height: 300

    // 默认组件：assistant 颜色经 __assistantColor 参数注入（JS 属性映射
    // 无法内联 QML 对象字面量——createTemporaryObject 的属性在组件完成前
    // 应用，播种读到的就是注入色）
    Component {
        id: wheelComp
        HSVWheel {
            id: wheel
            width: 200
            height: 200
            animationEnabled: false
            property color __assistantColor: "#ff0000"
            colorAssistant: ColorAssistant {
                color: wheel.__assistantColor
            }
        }
    }

    function makeWheel(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(wheelComp, root, props)
    }

    // 光标定位（objectName 定位——组件内部对象零暴露原则的测试例外：
    // 光标是公开视觉契约，tst_colorchannelslider 同款惯例）
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

    function cursorOf(w) {
        return findChild(w, "wheelCursor")
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 三值双向同步（接口契约）——
    function test_chainSync() {
        const w = makeWheel({})
        const ca = w.colorAssistant
        // 初始：red → hsvHueF=0、sat=1、value=1
        verify(fuzzy(ca.hsvHueF, 0), "red initial hue")
        verify(fuzzy(ca.hsvSaturationF, 1), "red initial sat")
        verify(fuzzy(ca.hsvValueF, 1), "red initial value")
        // 写方向：接口属性 → assistant 通道
        w.hue = 0.5
        verify(fuzzy(ca.hsvHueF, 0.5), "hue write -> assistant")
        w.saturation = 0.4
        verify(fuzzy(ca.hsvSaturationF, 0.4), "sat write -> assistant")
        w.value = 0.7
        verify(fuzzy(ca.hsvValueF, 0.7), "value write -> assistant")
        // 读方向：assistant 通道 → 接口属性
        ca.hsvHueF = 0.3
        verify(fuzzy(w.hue, 0.3), "assistant hue -> interface")
        ca.hsvSaturationF = 0.6
        verify(fuzzy(w.saturation, 0.6), "assistant sat -> interface")
        ca.hsvValueF = 0.9
        verify(fuzzy(w.value, 0.9), "assistant value -> interface")
    }

    // —— 同值写入不循环（相等守卫收敛）——
    function test_sameValueConvergence() {
        const w = makeWheel({})
        const ca = w.colorAssistant
        const spy = Qt.createQmlObject(
                        'import QtTest; SignalSpy { signalName: "valueChanged" }',
                        root, "")
        spy.target = w
        w.value = 0.5
        verify(fuzzy(ca.hsvValueF, 0.5), "write chain works")
        verify(spy.count >= 1 && spy.count <= 3, "new write bounded settle")
        const countAfterWrite = spy.count
        // 精确同值写回（当前存储值）→ 无 valueChanged（无环）
        w.value = w.value
        compare(spy.count, countAfterWrite, "same-value write -> no storm")
        verify(fuzzy(w.value, 0.5), "value stable after settle")
    }

    // —— onCompleted 播种：assistant 预设色 → 回读 ——
    function test_seed() {
        const w = makeWheel({})
        verify(fuzzy(w.hue, 0), "red -> hue 0 seeded")
        verify(fuzzy(w.saturation, 1), "red -> sat 1 seeded")
        verify(fuzzy(w.value, 1), "red -> value 1 seeded")
        const g = makeWheel({ __assistantColor: "#404040" })
        // #404040: hsvHue=-1 (grey), sat=0, value=0.25
        verify(fuzzy(g.value, 0.25), "grey -> value 0.25 seeded")
        verify(fuzzy(g.saturation, 0), "grey -> sat 0 seeded")
        verify(fuzzy(g.hue, 0), "grey hue not seeded -> keep default 0")
    }

    // —— hue 越界（<0 无色相）接口写入不写进 assistant ——
    function test_hueOutOfRange() {
        const w = makeWheel({})
        const ca = w.colorAssistant
        verify(fuzzy(ca.hsvHueF, 0), "red hue valid")
        w.hue = -1
        verify(fuzzy(ca.hsvHueF, 0), "hue<0 not written to assistant")
        w.hue = -0.5
        verify(fuzzy(ca.hsvHueF, 0), "hue<0 still not written")
    }

    // —— 钳制：sat/value clamp [0,1]（接口属性与 assistant 都收敛）——
    function test_clamp() {
        const w = makeWheel({})
        w.saturation = 1.5
        verify(fuzzy(w.colorAssistant.hsvSaturationF, 1), "sat upper clamp")
        verify(fuzzy(w.saturation, 1), "sat itself reads 1")
        w.saturation = -0.5
        verify(fuzzy(w.colorAssistant.hsvSaturationF, 0), "sat lower clamp")
        verify(fuzzy(w.saturation, 0), "sat itself reads 0")
        w.value = 1.5
        verify(fuzzy(w.colorAssistant.hsvValueF, 1), "value upper clamp")
        verify(fuzzy(w.value, 1), "value itself reads 1")
        w.value = -0.5
        verify(fuzzy(w.colorAssistant.hsvValueF, 0), "value lower clamp")
        verify(fuzzy(w.value, 0), "value itself reads 0")
        // hue >1 圆周归一化（对齐 QColor::setHsvF 循环等价存储）。
        // 注意：sat=0（无色相）时 QColor 存储灰色 → hsvHueF=-1，hue 写入
        // 无彩色无效（ColorChannelSlider 用 sat-bump 解决的同类问题，本件
        // 范围未含）——故 hue 归一化在**独立组件**上测（fresh hue 为红
        // hue=0、sat=1 有彩色），不掺 sat=0 场景。
        const hw = makeWheel({})
        hw.hue = 1.5
        verify(fuzzy(hw.hue, 0.5), "hue 1.5 -> normalized 0.5")
        verify(Math.abs(hw.colorAssistant.hsvHueF - 0.5) < 0.02,
               "assistant hue normalized (quantized)")
        hw.hue = 2
        verify(fuzzy(hw.hue, 0), "hue 2 -> normalized 0")
        verify(Math.abs(hw.colorAssistant.hsvHueF) < 0.02,
               "assistant hue normalized 0 (quantized)")
    }

    // —— value 驱动圆盘压暗层（darkAlpha = 1 - value 派生契约）——
    // HSVSurface 的压暗层 alpha 经 darkAlpha 只读派生暴露（Shape 内
    // ShapePath 不可经 children 遍历）。通过 HSVWheel 的 surface 对象
    // 不可直接访问（零暴露），故经 assistant 联动 + 组件契约间接验证：
    // value 接口写 → assistant.hsvValueF → 压暗层驱动源。此处验证值链
    // 契约，视觉压暗层由用户运行验证（AGENTS 分级惯例）。
    function test_valueDrivesDarken() {
        const w = makeWheel({})
        // value 接口写 → assistant 联动（value 是压暗层驱动源）
        w.value = 0.3
        verify(fuzzy(w.colorAssistant.hsvValueF, 0.3), "value -> assistant")
        // 断言值链契约：darkAlpha 派生公式在 HSVSurface 内定义（1 - value），
        // 此处验证 HSVWheel 的 value 接口正确投影到压暗层数据源。视觉 alpha
        // 渲染由人工运行验证覆盖。
        verify(fuzzy(1 - w.colorAssistant.hsvValueF, 0.7), "darkAlpha = 1 - value")
    }

    // —— 光标定位派生：值合法 → 光标恒在圆内（无越界）——
    function test_cursorWithinCircle() {
        const w = makeWheel({})
        const c = cursorOf(w)
        verify(c !== null, "cursor exists")
        const cx = w.width / 2
        const cy = w.height / 2
        const radius = Math.min(w.width, w.height) / 2
        // red: hue 0, sat 1 → 光标在圆周（距圆心 = radius）
        w.hue = 0
        w.saturation = 1
        tryVerify(function () {
            const dx = c.centerx - cx
            const dy = c.centery - cy
            return Math.abs(Math.sqrt(dx * dx + dy * dy) - radius) < 0.001
        }, 500, "sat 1 -> cursor on rim")
        // sat 0 → 圆心
        w.saturation = 0
        tryVerify(function () {
            return fuzzy(c.centerx, cx) && fuzzy(c.centery, cy)
        }, 500, "sat 0 -> cursor at center")
        // 中间值在圆内
        w.hue = 0.25
        w.saturation = 0.5
        tryVerify(function () {
            const dx = c.centerx - cx
            const dy = c.centery - cy
            return Math.sqrt(dx * dx + dy * dy) < radius
        }, 500, "sat 0.5 -> cursor inside circle")
    }

    // —— 交互契约裁剪：无 defaultValue/reset ——
    function test_noReset() {
        const w = makeWheel({})
        verify(w.reset === undefined, "no reset function")
        verify(w.defaultValue === undefined, "no defaultValue property")
        // value 播种后不被意外重置（无 reset 触发源）
        w.value = 0.8
        verify(fuzzy(w.value, 0.8), "value write persists")
        verify(fuzzy(w.colorAssistant.hsvValueF, 0.8), "assistant follows")
    }

    // —— 光标恒不越界（值域合法的派生保证）——
    function test_valueDomain() {
        const w = makeWheel({})
        w.hue = 0.99
        w.saturation = 1
        w.value = 1
        const ca = w.colorAssistant
        verify(fuzzy(ca.hsvHueF, 0.99), "hue in domain")
        verify(fuzzy(ca.hsvSaturationF, 1), "sat in domain")
        verify(fuzzy(ca.hsvValueF, 1), "value in domain")
        const c = cursorOf(w)
        const cx = w.width / 2
        const cy = w.height / 2
        const radius = Math.min(w.width, w.height) / 2
        tryVerify(function () {
            const dx = c.centerx - cx
            const dy = c.centery - cy
            return Math.sqrt(dx * dx + dy * dy) <= radius + 0.001
        }, 500, "cursor never outside circle")
    }
}
