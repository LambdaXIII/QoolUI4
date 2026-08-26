import QtQuick
import QtTest
import Qool
import Qool.Color

// ChannelBoxSlider 逻辑契约测试（Qool.Color/ChannelBoxSlider.qml
// ——T.Slider 平级竖直通道滑块：填充条样式轨道 + 透明手柄 + colorAssistant
// 无条件双向链）。
//
// 被测契约（仅逻辑/行为——外观已定稿，不测视觉细节）：
// - 链双向同步：写 value → assistant 通道变化；改 assistant 通道 → value
//   回写；同值写入不循环（T.Slider 同值守卫 + assistant 相等守卫收敛）
// - onCompleted 播种：assistant 预设色 → value = 通道值（hue 恒合法一律
//   播种——锚 ∈[0,1)，灰轴种子 0）
// - hue 直写落锚：灰轴（sat=0）上 hue 写仍生效（锚语义，sat-bump 已退役）
// - 裁剪：越界写入收敛 [0,1]（外部程序写入唯一越界来源）
// - NaN 写入：不写 assistant、无死循环（守卫路径）
// - 初始默认：通道值即 1 或未播种时 value = 1
// - channel 分派：不同 channel 的 value 写入落到对应通道；动态切换 channel
//   后写入落到新通道
// - 契约裁剪：无 defaultValue/reset（显式断言）
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范）。

TestCase {
    id: root

    name: "ChannelBoxSlider"
    width: 400
    height: 300

    // 默认组件：竖直 40×200、默认 channel 显式设为 HSLLightness（方便播种
    // 断言 red→0.5）；assistant 颜色经 __assistantColor 参数注入（JS 属性
    // 映射无法内联 QML 对象字面量——createTemporaryObject 的属性在组件
    // 完成前应用，播种读到的就是注入色）
    Component {
        id: sliderComp
        ChannelBoxSlider {
            id: slider
            width: 40
            height: 200
            animationEnabled: false
            property color __assistantColor: "#ff0000"
            colorAssistant: ColorAssistant {
                color: slider.__assistantColor
            }
            channel: ColorHQ.HSLLightness
        }
    }

    function makeSlider(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(sliderComp, root, props)
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }
    function findItem(item, name) {
        if (item.objectName === name)
            return item
        for (let i = 0; i < item.children.length; ++i) {
            const r = findItem(item.children[i], name)
            if (r)
                return r
        }
        return null
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
        // hue + 灰色：锚 hue=0 恒合法 → 播种发生（value=0，非默认 1）
        const g = makeSlider({
                      __assistantColor: "#808080",
                      channel: ColorHQ.HSVHue
                  })
        verify(fuzzy(g.value, 0), "achromatic hue seeded -> 0")
        // 灰上 hue 直写落锚（显式写恒生效，无需 sat-bump；锚冻结无量化）
        g.value = 0.25
        verify(fuzzy(g.colorAssistant.hsvHueF, 0.25),
               "hue write lands on gray (anchor)")
        verify(fuzzy(g.value, 0.25), "value reads back written hue")
    }

    // —— channel 分派：value 写入落到对应通道；动态切换后落到新通道 ——
    function test_channelDispatch() {
        const v = makeSlider({ channel: ColorHQ.HSVValue })
        v.value = 0.4
        verify(fuzzy(v.colorAssistant.hsvValueF, 0.4), "HSVValue write lands")
        const a = makeSlider({ channel: ColorHQ.Alpha })
        a.value = 0.6
        verify(fuzzy(a.colorAssistant.alphaF, 0.6), "Alpha write lands")
        // 动态切换 channel：写入落到新通道
        const d = makeSlider({})
        d.channel = ColorHQ.HSVValue
        d.value = 0.8
        verify(fuzzy(d.colorAssistant.hsvValueF, 0.8),
               "write lands on switched channel")
    }

    // —— 契约裁剪显式断言（QoolUITests/AGENTS——锁定裁剪不被回填）——
    function test_contractCulled() {
        const s = makeSlider({})
        verify(s.defaultValue === undefined, "no defaultValue (contract culled)")
        verify(s.reset === undefined, "no reset (contract culled)")
    }
    // —— 边框高亮：值变化 → 提亮，latch 窗口后回落（TimerLatch 电平，
    // 无公开状态——经轨道边框色可观察行为锁定）——
    // 注：onCompleted 播种写 value 亦触发 latch，故先等窗口走完回到
    // 基色再验证完整周期。HSLLightness 的通道标识色为静态灰（不随值
    // 变），边框色差全部来自高亮本身。
    function test_borderHighlight() {
        const s = makeSlider({})
        const track = findItem(s, "track")
        verify(track, "track found by objectName")
        const window = Style.movementDuration * 2
        wait(window + 100)
        const base = track.borderColor.toString()
        s.value = 0.3
        verify(track.borderColor.toString() !== base,
               "value write -> border highlighted")
        wait(window + 100)
        verify(track.borderColor.toString() === base,
               "latch window elapsed -> border back to base")
    }
}
