import QtQuick
import QtTest
import Qool
import Qool.Color

// ColorChannelSlider 测试（Qool.Color/ColorChannelSlider.qml——T.Slider 平级
// 通道滑块：channel 通用寻址 + colorAssistant 无条件双向链 + 轨道按通道渐变
// + 光标显示实色）。
//
// 被测契约（外部行为与公开契约——docs/reference/Qool.Color/ColorChannelSlider.md
// 为准绳，逐条对应）：
// - 链双向同步：写 value → assistant 通道变化；改 assistant 通道 → value
//   回写；同值写入不循环（T.Slider 同值守卫 + assistant 相等守卫收敛）
// - onCompleted 播种：assistant 预设色 → value = 通道值（越界 hue 不播种）
// - sat-bump：hue 通道 + 无色相色（hue < 0）→ 先写对应 sat = 0.001 再写 hue
// - 裁剪：越界写入收敛 [0,1]（外部程序写入唯一越界来源）
// - 初始默认：无播种（通道值即 1 / hue+无色相）时 value = 1
// - channel 分派：hue → 彩虹轨道（11 stops）；非 hue → 双色轨道；handle 实例
// - 渐变端点：静态通道（RGB/Value/Lightness/CMYK）端点色；动态通道
//   （Alpha/Sat）随 assistant 变化
// - 光标显示实色（assistant.solidColor）
// - 轨道几何：收缩模型（side/shrinkSize）+ 居中；orientation/RTL 渐变锚定
//   值增大视觉端（ADR-0010 模式）
// - background 模板插拔安全（替换后尺寸仍受控）
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 真实鼠标交互（拖动/键盘）不在自动化范围（offscreen 不注入合成事件，
// 与 tst_slider 同策略）——交互映射以几何断言 + Playground 人工验收覆盖。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "ColorChannelSlider"
    width: 400
    height: 300

    // 默认组件：assistant 颜色经 __assistantColor 参数注入（JS 属性映射
    // 无法内联 QML 对象字面量——createTemporaryObject 的属性在组件完成前
    // 应用，播种读到的就是注入色）
    Component {
        id: sliderComp
        ColorChannelSlider {
            id: slider
            width: 200
            height: 40
            animationEnabled: false
            property color __assistantColor: "#ff0000"
            colorAssistant: ColorAssistant {
                color: slider.__assistantColor
            }
            channel: ColorNameHQ.HSLLightness
        }
    }

    function makeSlider(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(sliderComp, root, props)
    }

    // 内部可视对象读取（objectName 定位——组件内部对象零暴露原则的测试
    // 例外：轨道静态性与光标实色是公开视觉契约，tst_slider 同款惯例）
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

    function trackOf(s) {
        return findChild(s.background, "track")
    }

    // 光标 = handle 壳（Item）内联 CrystalCursor（ADR-0016 收束）——断言
    // 其公开契约（color = 实色）
    function handleCrystal(s) {
        return s.handle.children[0]
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    function colorEqual(a, b) {
        return a.toString() === b.toString()
    }

    // —— 链双向同步（文档 Sync 契约）——
    function test_chainSync() {
        const s = makeSlider({})
        const ca = s.colorAssistant
        // 写方向：value → assistant 通道 + 颜色联动
        verify(fuzzy(ca.hslLightnessF, 0.5), "initial channel = red lightness 0.5")
        s.value = 0.35
        verify(fuzzy(ca.hslLightnessF, 0.35), "value write -> assistant channel")
        verify(!colorEqual(ca.color, "#ff0000"), "value write -> color follows")
        // 读方向：assistant 通道 → value 回写
        ca.hslLightnessF = 0.7
        verify(fuzzy(s.value, 0.7), "assistant change -> value follows")
    }

    // —— 同值写入不循环（链收敛）——
    // 实证：新值写入产生有界落定（valueChanged → caChanged → 回读修正
    // ——assistant 内部色值量化 ~1e-5 级，value 收敛到真实存储值，一次性
    // 落定）；精确同值写入（当前存储值写回）零信号——T.Slider 同值守卫
    // + assistant 相等守卫。信号同步触发——无需 wait。
    function test_sameValueConvergence() {
        const s = makeSlider({})
        const ca = s.colorAssistant
        const spy = Qt.createQmlObject(
                        'import QtTest; SignalSpy { signalName: "valueChanged" }',
                        root, "")
        spy.target = s
        s.value = 0.3
        verify(fuzzy(ca.hslLightnessF, 0.3), "write chain works")
        verify(spy.count >= 1 && spy.count <= 3, "new write bounded settle")
        const countAfterWrite = spy.count
        // 精确同值写回（当前存储值）→ 无 valueChanged（无环）
        s.value = s.value
        compare(spy.count, countAfterWrite, "same-value write -> no storm")
        // assistant 回写同值 → 无再入（收敛）
        ca.hslLightnessF = ca.hslLightnessF
        spy.wait(10)
        compare(spy.count, countAfterWrite, "assistant same-value -> no reentry")
        verify(fuzzy(s.value, 0.3), "value stable after settle")
    }

    // —— onCompleted 播种：assistant 预设色 → value = 通道值 ——
    function test_seed() {
        const s = makeSlider({})
        verify(fuzzy(s.value, 0.5), "red -> lightness 0.5 seeded")
        const g = makeSlider({ __assistantColor: "#404040" })
        verify(fuzzy(g.value, 0.25), "#404040 -> lightness 0.25 seeded")
        const w = makeSlider({ __assistantColor: "white" })
        verify(fuzzy(w.value, 1), "white -> lightness 1 seeded")
    }

    // —— sat-bump：hue + 无色相色 → 先写 sat 0.001 再写 hue ——
    // 注：QColor 近灰（sat≈0.001）内部量化——sat 0.001 存为 ~0.001007、
    // hue 存值偏差 ~2.5e-3（RGB 表示无法精确保住近灰 hue）——断言用宽
    // 容差（sat 非零小量 + hue 近似），契约是"sat 抬离 0 使 hue 有定义"
    // 的可见反馈，非精确值。
    function test_satBump() {
        // HSV hue + 灰色（hsvHueF = -1）
        const s = makeSlider({
                      __assistantColor: "#808080",
                      channel: ColorNameHQ.HSVHue
                  })
        verify(s.colorAssistant.hsvHueF < 0, "gray has invalid hue")
        s.value = 0.5
        verify(Math.abs(s.colorAssistant.hsvSaturationF - 0.001) < 0.0005,
               "sat-bump writes sat 0.001 (quantized)")
        verify(fuzzy(s.colorAssistant.hsvHueF, 0.5), "hue written after bump")
        // HSL hue + 灰色
        const h = makeSlider({
                      __assistantColor: "#404040",
                      channel: ColorNameHQ.HSLHue
                  })
        h.value = 0.3
        verify(Math.abs(h.colorAssistant.hslSaturationF - 0.001) < 0.0005,
               "HSL sat-bump writes its sat")
        verify(Math.abs(h.colorAssistant.hslHueF - 0.3) < 0.01,
               "HSL hue written after bump (quantized)")
    }

    // —— hue 拖动在彩色上不 bump（sat 保持）——
    function test_noBumpOnChromatic() {
        const s = makeSlider({ channel: ColorNameHQ.HSVHue })
        // red → hsvHueF = 0
        verify(fuzzy(s.colorAssistant.hsvHueF, 0), "red hue = 0 (valid)")
        s.value = 0.2
        verify(fuzzy(s.colorAssistant.hsvSaturationF, 1), "sat not bumped")
        verify(fuzzy(s.colorAssistant.hsvHueF, 0.2), "hue written directly")
    }

    // —— 裁剪：越界写入收敛 [0,1] ——
    function test_clamp() {
        const s = makeSlider({})
        s.value = 1.5
        verify(fuzzy(s.colorAssistant.hslLightnessF, 1), "upper clamp to 1")
        verify(fuzzy(s.value, 1), "value itself reads 1")
        s.value = -0.5
        verify(fuzzy(s.colorAssistant.hslLightnessF, 0), "lower clamp to 0")
        verify(fuzzy(s.value, 0), "value itself reads 0")
        s.value = 0.5
        verify(fuzzy(s.colorAssistant.hslLightnessF, 0.5), "in-range normal")
    }

    // —— 初始默认：无播种时 value = 1 ——
    function test_initialDefault() {
        // white → lightness 1：播种值与默认一致（value 保持 1）
        const w = makeSlider({ __assistantColor: "white" })
        verify(fuzzy(w.value, 1), "channel already 1 -> keeps default 1")
        // hue + 无色相色：hue = -1 越界不播种 → 保持默认 1（hue 1≡0
        // 循环等价无副作用）
        const g = makeSlider({
                      __assistantColor: "#808080",
                      channel: ColorNameHQ.HSVHue
                  })
        verify(fuzzy(g.value, 1), "achromatic hue not seeded -> default 1")
        // 灰色上 hue 拖动仍可写（sat-bump 路径贯通——近灰量化容差）
        g.value = 0.25
        verify(Math.abs(g.colorAssistant.hsvHueF - 0.25) < 0.01,
               "drag on gray works from default 1")
    }

    // —— channel 分派：hue → 彩虹轨道（11 stops）；非 hue → 双色轨道 ——
    function test_channelDispatch() {
        const h = makeSlider({ channel: ColorNameHQ.HSVHue })
        const hueTrack = trackOf(h)
        verify(hueTrack !== null, "hue track exists")
        const hueGradient = hueTrack.fillGradient
        verify(hueGradient !== undefined, "hue gradient exists")
        compare(hueGradient.stops.length, 11, "hue rainbow 11 stops")
        verify(colorEqual(hueGradient.stops[0].color, Qt.hsva(0, 1, 1, 1)),
               "hue first stop full sat/value")
        verify(colorEqual(hueGradient.stops[10].color, Qt.hsva(1, 1, 1, 1)),
               "hue last stop = hsva(1,1,1) == 0")
        // HSL hue 同样彩虹
        const hl = makeSlider({ channel: ColorNameHQ.HSLHue })
        compare(trackOf(hl).fillGradient.stops.length, 11, "HSL hue same rainbow")
        // 非 hue → 双色
        const s = makeSlider({ channel: ColorNameHQ.HSLLightness })
        compare(trackOf(s).fillGradient.stops.length, 2, "non-hue dual-color")
        // handle 实例正确
        verify(h.handle !== null, "handle exists")
        verify(h.handle.width === 40, "handle side = normal size")
    }

    // —— 静态渐变端点（文档 Gradient semantics 表）——
    function test_staticEndpoints() {
        // RGB：黑 → 纯通道色
        const r = makeSlider({ channel: ColorNameHQ.Red })
        const rg = trackOf(r).fillGradient
        verify(colorEqual(rg.stops[0].color, "#000000"), "Red from = black")
        verify(colorEqual(rg.stops[1].color, "#ff0000"), "Red to = pure red")
        const b = makeSlider({ channel: ColorNameHQ.Blue })
        verify(colorEqual(trackOf(b).fillGradient.stops[1].color, "#0000ff"),
               "Blue to = pure blue")
        // Value/Lightness：黑 → 白
        const v = makeSlider({ channel: ColorNameHQ.HSVValue })
        verify(colorEqual(trackOf(v).fillGradient.stops[1].color, "#ffffff"),
               "Value to = white")
        const l = makeSlider({ channel: ColorNameHQ.HSLLightness })
        verify(colorEqual(trackOf(l).fillGradient.stops[0].color, "#000000"),
               "Lightness from = black")
        verify(colorEqual(trackOf(l).fillGradient.stops[1].color, "#ffffff"),
               "Lightness to = white")
        // CMYK：白 → 纯通道色（墨量 0 = 纸白）
        const c = makeSlider({ channel: ColorNameHQ.Cyan })
        verify(colorEqual(trackOf(c).fillGradient.stops[0].color, "#ffffff"),
               "Cyan from = white")
        verify(colorEqual(trackOf(c).fillGradient.stops[1].color, "#00ffff"),
               "Cyan to = pure cyan")
        const k = makeSlider({ channel: ColorNameHQ.Black })
        verify(colorEqual(trackOf(k).fillGradient.stops[1].color, "#000000"),
               "Black to = pure black")
    }

    // —— 动态渐变端点：Alpha/Sat 随 assistant 变化 ——
    function test_dynamicEndpoints() {
        // Alpha：transparent → solidColor（去 alpha 当前实色）
        const a = makeSlider({ channel: ColorNameHQ.Alpha })
        const ag = trackOf(a).fillGradient
        verify(ag.stops[0].color.a === 0, "Alpha from = transparent")
        verify(colorEqual(ag.stops[1].color, "#ff0000"), "Alpha to = solid color")
        a.colorAssistant.color = "#00ff00"
        tryVerify(function () {
            return colorEqual(ag.stops[1].color, "#00ff00")
        }, 500, "Alpha to follows color change")
        // HSVSaturation：灰(当前亮度) → hsva(hue, 1, value)——随 hue/value
        const s = makeSlider({ channel: ColorNameHQ.HSVSaturation })
        // red：hue 0、value 1 → from = hsva(0,0,1)=白灰、to = hsva(0,1,1)=红
        const sg = trackOf(s).fillGradient
        verify(colorEqual(sg.stops[0].color, Qt.hsva(0, 0, 1, 1)),
               "Sat from = gray at current value")
        verify(colorEqual(sg.stops[1].color, Qt.hsva(0, 1, 1, 1)),
               "Sat to = full sat at current hue")
        // assistant 变色 → 端点跟随（hue/value 新值）
        s.colorAssistant.color = "#404080"   // hsvHue ~= 2/3, value ~= 0.5
        tryVerify(function () {
            return colorEqual(
                sg.stops[1].color,
                Qt.hsva(s.colorAssistant.hsvHueF, 1, s.colorAssistant.hsvValueF, 1))
        }, 500, "Sat to follows hue/value")
        // HSLSaturation：灰(当前亮度) → hsla(hue, 1, lightness)
        const h = makeSlider({ channel: ColorNameHQ.HSLSaturation })
        const hg = trackOf(h).fillGradient
        verify(colorEqual(hg.stops[0].color, Qt.hsla(0, 0, 0.5, 1)),
               "HSL Sat from = gray at current lightness")
        verify(colorEqual(hg.stops[1].color, Qt.hsla(0, 1, 0.5, 1)),
               "HSL Sat to = full sat at current hue")
    }

    // —— 光标显示当前实色（assistant.solidColor，所见即所得）——
    function test_handleColor() {
        const s = makeSlider({})
        const c = handleCrystal(s)
        verify(c !== null, "handle crystal exists")
        verify(colorEqual(c.color, "#ff0000"), "handle = current solid color")
        s.colorAssistant.color = "#0040ff"
        tryVerify(function () {
            return colorEqual(c.color, "#0040ff")
        }, 500, "handle follows color change")
    }

    // —— 轨道几何：收缩模型（side/shrinkSize）+ 居中 ——
    // 家族模型（Qool.Controls.Slider 同款）：轨道沿主轴与法向双维收缩
    // （width/height 均 − shrinkSize）+ 全向居中——展开光标"顶出轨道但
    // 不出控件"三心对齐。
    function test_trackGeometry() {
        // 200×40 → side = availableHeight = 40 → shrinkSize = bound(3,10,25)=10
        const s = makeSlider({})
        const t = trackOf(s)
        verify(t !== null, "track exists")
        compare(t.width, 200 - 10, "track shrinks on main axis")
        compare(t.height, 40 - 10, "track shrinks on normal axis")
        compare(t.x, 5, "track centered on main axis")
        compare(t.y, (40 - 30) / 2, "track centered on normal axis")
        verify(colorEqual(t.borderColor, s.colorAssistant.recommendedForegroundColor),
               "track border = assistant recommended fg")
        // 轨道静态——值写入不改变轨道几何
        s.value = 0.5
        compare(t.width, 190)
        compare(t.height, 30)
        compare(t.y, 5)
    }

    // —— 渐变锚定：水平 LTR from 左 → to 右（cut 切角内侧）——
    // 锚定用轨道自身尺寸（收缩后 190×30 → cut = 15）
    function test_gradientAnchorsHorizontal() {
        const s = makeSlider({ channel: ColorNameHQ.HSVValue })
        const g = trackOf(s).fillGradient
        compare(g.x1, 15, "from anchored at inner left cut")
        compare(g.x2, 190 - 15, "to anchored at inner right cut")
        compare(g.y1, 15, "horizontal y centered")
        compare(g.y2, 15)
    }

    // —— 垂直：渐变 from 底 → to 顶（Qt 垂直惯例，ADR-0010）——
    // 垂直 40×200 → 轨道 30×190（双维收缩）→ cut = 15
    function test_verticalGradient() {
        const s = makeSlider({ orientation: Qt.Vertical, width: 40, height: 200,
                               channel: ColorNameHQ.HSVValue })
        const g = trackOf(s).fillGradient
        compare(g.y1, 190 - 15, "vertical from at bottom (low end)")
        compare(g.y2, 15, "vertical to at top (value end)")
        compare(g.x1, 15, "vertical x centered")
        compare(g.x2, 15)
    }

    // —— RTL：渐变端点对调（值增大视觉端左移，ADR-0010）——
    function test_rtlGradient() {
        const s = makeSlider({ channel: ColorNameHQ.HSVValue })
        s.LayoutMirroring.enabled = true
        tryCompare(s, "mirrored", true)
        const g = trackOf(s).fillGradient
        compare(g.x1, 190 - 15, "RTL from moved right (swapped)")
        compare(g.x2, 15, "RTL to moved left")
        compare(g.y1, 15, "RTL horizontal y still centered")
        // handle 值增大靠左（visualPosition 反转驱动）——value 经链落定
        // 到 assistant 存储值（~1e-5 量化），位置用容差
        s.value = 0.75
        verify(Math.abs(s.handle.x - 0.25 * (200 - 40)) < 0.01,
               "RTL value increase -> handle moves left")
    }

    // —— 垂直 handle 定位（visualPosition 恒反转）——
    function test_verticalHandle() {
        const s = makeSlider({ orientation: Qt.Vertical, width: 40, height: 200 })
        compare(s.handle.width, 40, "handle side = normal size")
        compare(s.handle.x, 0, "vertical handle x centered")
        s.value = 0
        compare(s.handle.y, 200 - 40, "value 0 -> bottom (visualPosition 1)")
        s.value = 1
        compare(s.handle.y, 0, "value 1 -> top (visualPosition 0)")
    }

    // —— 值变化 → handle 位置跟随（displayValue 中间层）——
    function test_handlePositionFollowsValue() {
        const s = makeSlider({})
        s.value = 0.5
        compare(s.handle.x, 0.5 * (200 - 40), "value 0.5 -> midpoint")
        s.value = 0
        compare(s.handle.x, 0, "value 0 -> left end")
        s.value = 1
        compare(s.handle.x, 200 - 40, "value 1 -> right end")
    }

    // —— background 模板插拔安全（替换后尺寸仍受控）——
    function test_backgroundPluggable() {
        const s = makeSlider({})
        s.background = Qt.createQmlObject(
            'import QtQuick; Item { objectName: "customBg" }', root, "")
        // 替换后 background 由 Control 标准自动布局（root − insets）
        tryCompare(s.background, "width", 200, 500, "replaced bg width controlled")
        tryCompare(s.background, "height", 40, 500, "replaced bg height controlled")
        compare(s.background.objectName, "customBg", "background replaced")
    }

    // —— insets 响应：background 尺寸 = root − insets ——
    function test_insets() {
        const s = makeSlider({})
        s.leftInset = 10
        s.topInset = 4
        compare(s.background.width, 190, "leftInset shrinks bg width")
        compare(s.background.height, 36, "topInset shrinks bg height")
        const t = trackOf(s)
        compare(t.width, 190 - 10, "track width follows container")
        compare(t.height, 36 - 10, "track shrinks inside container")
    }
}
