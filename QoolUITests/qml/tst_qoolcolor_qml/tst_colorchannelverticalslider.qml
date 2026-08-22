import QtQuick
import QtTest
import Qool
import Qool.Color

// ColorChannelVerticalSlider 测试（Qool.Color/ColorChannelVerticalSlider.qml
// ——T.Slider 平级竖直通道滑块：填充条样式轨道 + 透明手柄 + colorAssistant
// 无条件双向链 + hue 彩虹原理式跟随）。
//
// 被测契约（外部行为与公开契约——docs/reference/Qool.Color/ColorChannelVerticalSlider.md
// 为准绳，逐条对应）：
// - 链双向同步：写 value → assistant 通道变化；改 assistant 通道 → value
//   回写；同值写入不循环（T.Slider 同值守卫 + assistant 相等守卫收敛）
// - onCompleted 播种：assistant 预设色 → value = 通道值（越界 hue 不播种）
// - sat-bump：hue 通道 + 无色相色（hue < 0）→ 先写对应 sat = 0.001 再写 hue
// - 裁剪：越界写入收敛 [0,1]（外部程序写入唯一越界来源）
// - 初始默认：无播种（通道值即 1 / hue+无色相）时 value = 1
// - channel 分派：hue → bg 彩虹（11 stops）；非 hue → bg 单色淡染（α0.1）
// - 填充几何：填充高度 = value × 内容区高、底部锚定（竖直默认）
// - 填充采样色：hue = 原理式（随当前 sat/value 或 sat/lightness）；非 hue
//   = 身份色字面量（Green #008000 / Alpha grey / Sat 原理式）
// - justMoved：写入 value → 边框 lighter 1.4×，1s 后回落（任何写入触发）
// - 契约裁剪：无 defaultValue/reset（显式断言 undefined）
// - 彩虹原理式跟随：改 assistant 色 → stops 颜色变化
// - 彩虹反排：顶部 stop = hue 1、底部 = hue 0
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 真实鼠标交互（拖动/键盘）不在自动化范围（offscreen 不注入合成事件，
// 与 tst_colorchannelslider 同策略）——交互映射以几何断言 + Playground
// 人工验收覆盖。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "ColorChannelVerticalSlider"
    width: 400
    height: 300

    // 默认组件：竖直 40×200、默认 channel 显式设为 HSLLightness（方便播种
    // 断言 red→0.5）；assistant 颜色经 __assistantColor 参数注入（JS 属性
    // 映射无法内联 QML 对象字面量——createTemporaryObject 的属性在组件
    // 完成前应用，播种读到的就是注入色）
    Component {
        id: sliderComp
        ColorChannelVerticalSlider {
            id: slider
            width: 40
            height: 200
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
    // 例外：填充条静态性与采样色是公开视觉契约，tst_slider 同款惯例）
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

    function fillRectOf(s) {
        return findChild(s.background, "fillRect")
    }

    function bgRectOf(s) {
        return findChild(s.background, "bgRect")
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

    // —— channel 分派：hue → bg 彩虹（11 stops）；非 hue → bg 单色淡染 ——
    function test_channelDispatch() {
        const h = makeSlider({ channel: ColorNameHQ.HSVHue })
        const t = trackOf(h)
        verify(t !== null, "track exists")
        verify(t.hueChannel === true, "hue channel flagged on track")
        const hueBg = bgRectOf(h)
        verify(hueBg.gradient !== undefined && hueBg.gradient !== null,
               "hue bg has gradient")
        compare(hueBg.gradient.stops.length, 11, "hue rainbow 11 stops")
        // HSL hue 同样彩虹
        const hl = makeSlider({ channel: ColorNameHQ.HSLHue })
        compare(bgRectOf(hl).gradient.stops.length, 11, "HSL hue same rainbow")
        // 非 hue → 无渐变 + 身份色 α0.1 淡染（HSLLightness 身份色 = white）
        const s = makeSlider({ channel: ColorNameHQ.HSLLightness })
        const sb = bgRectOf(s)
        verify(sb.gradient === undefined || sb.gradient === null,
               "non-hue bg has no gradient")
        verify(colorEqual(sb.color, Qt.alpha("#ffffff", 0.1)),
               "non-hue bg tinted alpha 0.1 identity")
        // 透明手柄实例（side×side——竖直 availableWidth）
        verify(h.handle !== null, "handle exists")
        compare(h.handle.width, 40, "handle side = normal size")
    }

    // —— 填充几何：高度 = value × 内容区高、底部锚定（竖直默认）——
    function test_fillGeometry() {
        const s = makeSlider({})
        const t = trackOf(s)
        const fr = fillRectOf(s)
        // content 区高 = track 高 − 2×4（padding 4 内缩）
        compare(fr.parent.height, t.height - 8, "content height = track - 2*padding")
        s.value = 0.5
        // 惰性绑定——读强制求值（onHeightChanged 同步触发）
        verify(fuzzy(fr.height, fr.parent.height * 0.5),
               "fill height = value * content height")
        verify(fuzzy(fr.y, fr.parent.height - fr.height),
               "fill anchored at bottom (y = content - height)")
    }

    // —— 填充采样色：hue 原理式；非 hue 身份色字面量 ——
    function test_sampleColor() {
        // hue 填充采样：HSVHue + red（hsvHueF=0、sat=1、value=1）→ value 0.5
        // → hsva(0.5, 1, 1, 1)（原理式——hue = value，sat/value 钉死当前）
        const h = makeSlider({ channel: ColorNameHQ.HSVHue })
        h.value = 0.5
        verify(colorEqual(trackOf(h).sampleColor, Qt.hsva(0.5, 1, 1, 1)),
               "HSV hue sample = hsva(value, sat, val)")
        // 非 hue 身份色（数据字面量逐字保留原变体 channelColor）
        const g = makeSlider({ channel: ColorNameHQ.Green })
        verify(colorEqual(trackOf(g).sampleColor, "#008000"),
               "Green identity = Qt named green (not #00ff00)")
        const a = makeSlider({ channel: ColorNameHQ.Alpha })
        verify(colorEqual(trackOf(a).sampleColor, "#808080"),
               "Alpha identity = grey")
        // Sat 原理式：red → hsva(hue 0, sat 1, value 1)——改 sat 后真实结果色
        const st = makeSlider({ channel: ColorNameHQ.HSVSaturation })
        verify(colorEqual(trackOf(st).sampleColor, Qt.hsva(0, 1, 1, 1)),
               "HSV Sat identity = principled (hsva(hue,1,value))")
    }

    // —— justMoved：写入 value → 边框 lighter 1.4×，1s 后回落 ——
    // 动画关闭（animationEnabled false）→ BasicColorBehavior 不启用、即时
    // 变色；回落用 wait（Timer 1s 区间实测策略）。
    function test_justMoved() {
        const s = makeSlider({})
        const t = trackOf(s)
        const br = findChild(s.background, "borderRect")
        const fr = fillRectOf(s)
        // 播种期 value 写入（默认 1 → red lightness 0.5）已触发过 when_moved
        // （或惰性绑定尚未求值）——先读高度强制求值 + 等回落，取稳定常态
        fr.height
        wait(1100)
        const normal = br.border.color
        s.value = 0.3
        fr.height  // 惰性绑定求值——onHeightChanged 同步触发 justMoved
        tryVerify(function () {
            return colorEqual(br.border.color, Qt.lighter(t.sampleColor, 1.4))
        }, 500, "justMoved highlight = lighter sample color")
        // 回落：Timer 1s 后回常态色
        wait(1100)
        tryVerify(function () {
            return colorEqual(br.border.color, normal)
        }, 500, "highlight falls back to normal after 1s")
    }

    // —— 契约裁剪显式断言（QoolUITests/AGENTS——锁定裁剪不被回填）——
    function test_contractCulled() {
        const s = makeSlider({})
        verify(s.defaultValue === undefined, "no defaultValue (contract culled)")
        verify(s.reset === undefined, "no reset (contract culled)")
    }

    // —— 彩虹原理式跟随：改 assistant 色 → stops 颜色变化 ——
    // 档 p = hsva(p, hsvSaturationF, hsvValueF, 0.2)——随当前 sat/value
    // 动态变化（对齐 HSVWheel/HSLBox 背景语义）
    function test_rainbowFollows() {
        const h = makeSlider({ channel: ColorNameHQ.HSVHue })
        const stops = bgRectOf(h).gradient.stops
        h.colorAssistant.color = "#404080"
        tryVerify(function () {
            return colorEqual(
                stops[0].color,
                Qt.hsva(1, h.colorAssistant.hsvSaturationF,
                        h.colorAssistant.hsvValueF, 0.2))
        }, 500, "rainbow top stop follows sat/value")
    }

    // —— 彩虹反排：顶部（position 0）= hue 1、底部（position 1）= hue 0 ——
    // QML Gradient position 0 = 顶部——spec 要求 hue 0 底部 → hue 1 顶部，
    // 故 stops 反排（红 assistant：hue 0 ≡ hue 1 同为红，用中间档辨向）
    function test_rainbowDirection() {
        const h = makeSlider({ channel: ColorNameHQ.HSVHue })
        const stops = bgRectOf(h).gradient.stops
        const sat = h.colorAssistant.hsvSaturationF  // red: 1
        const val = h.colorAssistant.hsvValueF       // red: 1
        verify(colorEqual(stops[0].color, Qt.hsva(1, sat, val, 0.2)),
               "top stop = hue 1")
        verify(colorEqual(stops[10].color, Qt.hsva(0, sat, val, 0.2)),
               "bottom stop = hue 0")
        // 反排判别：position 0.1 档 = hue 0.9（正确反排）而非 hue 0.1（顺排）
        verify(colorEqual(stops[1].color, Qt.hsva(0.9, sat, val, 0.2)),
               "second stop = hue 0.9 (reversed, not forward)")
    }
}
