import QtQuick
import QtTest
import Qool
import Qool.Color

// HSLBox 测试（Qool.Color/HSLBox.qml——v4 公开 HSL 二维取色表面：单向链
// 架构 + 三值双向接口 + 写入钳制两路 + 光标数据派生定位 + hue 外部驱动）。
//
// 被测契约（外部行为与公开契约——spec.md 为准绳，逐条对应）：
// - 三值双向同步：写 hue/saturation/lightness → assistant 对应通道；
//   assistant 变 → 回读；同值写入不循环（assistant 相等守卫收敛）
// - onCompleted 播种：assistant 预设色 → sat/ltn/hue 回读（越界 hue 不播种）
// - hue 越界（<0 无色相）接口写入不写进 assistant、显示保持
// - 钳制：sat/ltn clamp [0,1]、hue>1 归一化（接口属性与 assistant 都收敛）
// - 无 defaultValue/reset、双击无定义行为（交互契约裁剪）
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 真实鼠标交互（拖动）不在自动化范围（offscreen 不注入合成事件，与
// tst_hsvwheel 同策略）——交互映射以几何断言 + 人工运行验证覆盖。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "HSLBox"
    width: 400
    height: 300

    // 默认组件：assistant 颜色经 __assistantColor 参数注入（JS 属性映射
    // 无法内联 QML 对象字面量——createTemporaryObject 的属性在组件完成前
    // 应用，播种读到的就是注入色）
    Component {
        id: boxComp
        HSLBox {
            id: box
            width: 200
            height: 200
            animationEnabled: false
            property color __assistantColor: "#ff0000"
            colorAssistant: ColorAssistant {
                color: box.__assistantColor
            }
        }
    }

    function makeBox(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(boxComp, root, props)
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 三值双向同步（接口契约）——
    function test_chainSync() {
        const b = makeBox({})
        const ca = b.colorAssistant
        // 初始：red → hslHueF=0、sat=1、lightness=0.5（**HSL 语义：red 的
        // lightness 是 0.5 不是 1**——勿误当 HSV value）
        verify(fuzzy(ca.hslHueF, 0), "red initial hue")
        verify(fuzzy(ca.hslSaturationF, 1), "red initial sat")
        verify(fuzzy(ca.hslLightnessF, 0.5), "red initial lightness")
        // 写方向：接口属性 → assistant 通道
        b.hue = 0.5
        verify(fuzzy(ca.hslHueF, 0.5), "hue write -> assistant")
        b.saturation = 0.4
        verify(fuzzy(ca.hslSaturationF, 0.4), "sat write -> assistant")
        b.lightness = 0.7
        verify(fuzzy(ca.hslLightnessF, 0.7), "lightness write -> assistant")
        // 读方向：assistant 通道 → 接口属性
        ca.hslHueF = 0.3
        verify(fuzzy(b.hue, 0.3), "assistant hue -> interface")
        ca.hslSaturationF = 0.6
        verify(fuzzy(b.saturation, 0.6), "assistant sat -> interface")
        ca.hslLightnessF = 0.9
        verify(fuzzy(b.lightness, 0.9), "assistant lightness -> interface")
    }

    // —— 同值写入不循环（相等守卫收敛）——
    function test_sameValueConvergence() {
        const b = makeBox({})
        const ca = b.colorAssistant
        const spy = Qt.createQmlObject(
                        'import QtTest; SignalSpy { signalName: "lightnessChanged" }',
                        root, "")
        spy.target = b
        b.lightness = 0.5
        verify(fuzzy(ca.hslLightnessF, 0.5), "write chain works")
        verify(spy.count >= 1 && spy.count <= 3, "new write bounded settle")
        const countAfterWrite = spy.count
        // 精确同值写回（当前存储值）→ 无 lightnessChanged（无环）
        b.lightness = b.lightness
        compare(spy.count, countAfterWrite, "same-value write -> no storm")
        verify(fuzzy(b.lightness, 0.5), "lightness stable after settle")
    }

    // —— onCompleted 播种：assistant 预设色 → 回读 ——
    function test_seed() {
        const b = makeBox({})
        verify(fuzzy(b.hue, 0), "red -> hue 0 seeded")
        verify(fuzzy(b.saturation, 1), "red -> sat 1 seeded")
        verify(fuzzy(b.lightness, 0.5), "red -> lightness 0.5 seeded")
        const g = makeBox({ __assistantColor: "#404040" })
        // #404040: hslHue=-1 (grey), sat=0, lightness=0.25
        verify(fuzzy(g.lightness, 0.25), "grey -> lightness 0.25 seeded")
        verify(fuzzy(g.saturation, 0), "grey -> sat 0 seeded")
        verify(fuzzy(g.hue, 0), "grey hue not seeded -> keep default 0")
    }

    // —— hue 越界（<0 无色相）接口写入不写进 assistant ——
    function test_hueOutOfRange() {
        const b = makeBox({})
        const ca = b.colorAssistant
        verify(fuzzy(ca.hslHueF, 0), "red hue valid")
        b.hue = -1
        verify(fuzzy(ca.hslHueF, 0), "hue<0 not written to assistant")
        b.hue = -0.5
        verify(fuzzy(ca.hslHueF, 0), "hue<0 still not written")
    }

    // —— 钳制：sat/ltn clamp [0,1]（接口属性与 assistant 都收敛）——
    function test_clamp() {
        const b = makeBox({})
        b.saturation = 1.5
        verify(fuzzy(b.colorAssistant.hslSaturationF, 1), "sat upper clamp")
        verify(fuzzy(b.saturation, 1), "sat itself reads 1")
        b.saturation = -0.5
        verify(fuzzy(b.colorAssistant.hslSaturationF, 0), "sat lower clamp")
        verify(fuzzy(b.saturation, 0), "sat itself reads 0")
        b.lightness = 1.5
        verify(fuzzy(b.colorAssistant.hslLightnessF, 1), "lightness upper clamp")
        verify(fuzzy(b.lightness, 1), "lightness itself reads 1")
        b.lightness = -0.5
        verify(fuzzy(b.colorAssistant.hslLightnessF, 0), "lightness lower clamp")
        verify(fuzzy(b.lightness, 0), "lightness itself reads 0")
        // hue >1 圆周归一化（对齐 QColor::setHslF 循环等价存储）。
        // 注意：sat=0（无色相）时 QColor 存储灰色 → hslHueF=-1，hue 写入
        // 无彩色无效（ColorChannelSlider 用 sat-bump 解决的同类问题，本件
        // 范围未含）——故 hue 归一化在**独立组件**上测（fresh hue 为红
        // hue=0、sat=1 有彩色），不掺 sat=0 场景（与 tst_hsvwheel 的
        // test_clamp 同策略——不得在同一 box 先做完 sat clamp 再写 hue）。
        const hb = makeBox({})
        hb.hue = 1.5
        verify(fuzzy(hb.hue, 0.5), "hue 1.5 -> normalized 0.5")
        verify(Math.abs(hb.colorAssistant.hslHueF - 0.5) < 0.02,
               "assistant hue normalized (quantized)")
        hb.hue = 2
        verify(fuzzy(hb.hue, 0), "hue 2 -> normalized 0")
        verify(Math.abs(hb.colorAssistant.hslHueF) < 0.02,
               "assistant hue normalized 0 (quantized)")
    }

    // —— 交互契约裁剪：无 defaultValue/reset ——
    function test_noReset() {
        const b = makeBox({})
        verify(b.reset === undefined, "no reset function")
        verify(b.defaultValue === undefined, "no defaultValue property")
        // lightness 播种后不被意外重置（无 reset 触发源）
        b.lightness = 0.8
        verify(fuzzy(b.lightness, 0.8), "lightness write persists")
        verify(fuzzy(b.colorAssistant.hslLightnessF, 0.8), "assistant follows")
    }
}