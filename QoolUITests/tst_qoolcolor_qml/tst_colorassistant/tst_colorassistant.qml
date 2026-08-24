import QtQuick
import QtTest
import Qool
import Qool.Color

// ColorAssistant 测试（Qool.Color/qool_colorassistant.h——多色彩空间颜色
// 对象：写任一分量全空间重算 + 全 Changed 广播；int/F 双轨；列表与 name
// 属性；派生只读；QML_EXTENDED ColorLiterals 通道字面量扩展）。
//
// 被测契约（reference 文档 ColorAssistant.md 为准绳，逐条对应）：
// - 初始状态：未设色 isValid()=false，分量默认 0
// - color 写 → 四空间（RGB/HSV/HSL/CMYK）全同步；任一分量写 → 全空间重算
// - int/F 双轨语义一致且互写同步（F 轨 0..1、int 轨 0..255，hue 0..359）
// - 相等守卫：同值写入不广播（color/列表/分量三级守卫）
// - 信号：colorChanged + 列表 Changed 随色变无条件广播；分量 Changed
//   仅在分量实际变化时发射（选择性广播）
// - 列表属性：读 = 分量序列；写重建颜色；缺失条目用当前分量作默认；
//   相等守卫（同列表不广播）
// - 列表 alpha 语义：两路径统一保 alpha——分量写与无 a 位列表写都保留
//   当前 alpha（cmyk/cmykF/hsv/hsvF/hsl/hslF 一致）；rgba/rgbaF 含 a 位，
//   4 项列表写入即设置、短列表保留
// - 零 alpha 保通道（文档 Zero-alpha channel retention 节）：任一写入口
//   把 alpha 写 0 仅透明、不丢 RGB，恢复 alpha 即还原原色；全透明态下
//   solidColor 可取不透明变体、name 保持 #AARRGGBB 报通道；唯输入字面量
//   "transparent"/#00000000 在解析侧归零（输入语义，恢复 alpha 得黑）
// - 跨空间一致性（系统覆盖）：任一入口写后，四空间分量独立重建
//   （RGB/HSV/HSL 经 Qt.rgba/hsva/hsla、CMYK 经公式）与 color 指向同一
//   颜色；连续多步变化每步保持（test_crossSpaceConsistency /
//   test_continuousCrossSpaceFollow）
// - name：不透明 #RRGGBB / 半透明 #AARRGGBB（alphaF<1 判定）；写解析
//   生效；非法串 → 颜色无效（isValid()=false）
// - 派生只读：solidColor（alpha 强制 1）、visualBrightness（0.299/0.587/
//   0.114 加权）、recommendedForegroundColor（0.5 阈值：≥0.5 黑否则白）
// - 静态方法：hex/isValidName/isValid
// - 边界：灰色 hue=-1（无彩色 marker，fresh 组件隔离）
// - 越界行为（文档 Out-of-range 节，探针实证矩阵）：RGB/alpha 分量
//   双轨 clamp；int hue 分量 wrap（360→0、540→180）；HSV/HSL/CMYK 非
//   hue 分量（双轨）与 F hue → Invalid；列表入口越界全部 → Invalid
//   （含 hue 位——列表无 wrap）；rgbaF 例外：接受越界 float 为扩展
//   RGB（颜色有效，分量视图收敛回 [0,1]）；Invalid 后合法写恢复
// - 信号守卫全通道：全部 38 个可写属性同值重写各自静默、实质变化各自
//   恰好一次；单维变化矩阵（HSV value / HSL lightness / alpha / hue）——
//   空间内未变分量静默，列表/name/color 无条件广播族照发
// - 高负载确定性：120 轮 6 类入口交错写每轮四空间一致；绑定消费
//   （color/visualBrightness）高频写入即时跟随；重入回写（同值写回
//   模拟双向环）guard 拦截、每实质写恰好一次 colorChanged
// - QML 扩展：Channels 枚举（类型名访问）+ channelName/channelNameF/
//   channelTag/channelTagShort/channelColor/formatChannelNumberFloat/
//   parseChannelNumberFloat/clampChannelRange（经实例调用——类型名无
//   方法面，探针实证）
//
// 隔离：每个测试函数独立实例（makeCA）。hue 依赖有彩色的场景（无彩色
// 时 hue 写入无效——灰色 hue=-1）用 fresh 组件隔离，不掺灰场景。
//
// 容差：QColor 通道量化误差使 F 轨中间值回读必偏（0.5 → 0.5000076，
// journal 2026-08-23 颜色通道测试陷阱），F 轨断言一律 ≥0.02 容差；
// int 轨与端点值（0/1）量化精确，可精确断言。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范）。

TestCase {
    id: root

    name: "ColorAssistant"

    // 独立实例工厂：Component + createTemporaryObject（properties 在组件
    // 完成前应用——createTemporaryQmlObject 第三参是 filepath 无注入）
    Component {
        id: caComp
        ColorAssistant {}
    }

    function makeCA(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(caComp, root, props)
    }

    function makeSpy(target, signalName) {
        const spy = Qt.createQmlObject(
                    'import QtTest; SignalSpy { signalName: "colorChanged" }',
                    root, "")
        spy.signalName = signalName
        spy.target = target
        return spy
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.02
    }

    // —— 跨空间一致性校验：color 与四空间独立重建线互比 ——
    // RGB/HSV/HSL 用 Qt 原生构造（独立于被测对象）；CMYK 用标准公式
    // r=(1-c)(1-k)…（QML 无 Qt.cmyk）。灰 hue=-1 无意义，重建用 0。
    function sameColorF(a, b, label) {
        verify(fuzzy(a.r, b.r), label + " r")
        verify(fuzzy(a.g, b.g), label + " g")
        verify(fuzzy(a.b, b.b), label + " b")
        verify(fuzzy(a.a, b.a), label + " a")
    }

    function cmykToRgbF(c, m, y, k) {
        return { r: (1 - c) * (1 - k), g: (1 - m) * (1 - k), b: (1 - y) * (1 - k) }
    }

    function verifyConsistent(ca, label) {
        const c = ca.color
        sameColorF(c, Qt.rgba(ca.redF, ca.greenF, ca.blueF, ca.alphaF),
                   label + " rgb")
        const hh = ca.hsvHueF < 0 ? 0 : ca.hsvHueF
        sameColorF(c, Qt.hsva(hh, ca.hsvSaturationF, ca.hsvValueF, ca.alphaF),
                   label + " hsv")
        const hl = ca.hslHueF < 0 ? 0 : ca.hslHueF
        sameColorF(c, Qt.hsla(hl, ca.hslSaturationF, ca.hslLightnessF, ca.alphaF),
                   label + " hsl")
        const cr = cmykToRgbF(ca.cyanF, ca.magentaF, ca.yellowF, ca.blackF)
        verify(fuzzy(cr.r, ca.redF), label + " cmyk->rgb r")
        verify(fuzzy(cr.g, ca.greenF), label + " cmyk->rgb g")
        verify(fuzzy(cr.b, ca.blueF), label + " cmyk->rgb b")
    }

    // —— 初始状态：未设色无效、分量默认 0 ——
    function test_initialState() {
        const ca = makeCA({})
        verify(!ca.isValid(), "default instance invalid")
        compare(ca.red, 0, "red default 0")
        compare(ca.green, 0, "green default 0")
        compare(ca.blue, 0, "blue default 0")
        compare(ca.alpha, 0, "alpha default 0")
        compare(ca.hsvSaturation, 0, "hsvSat default 0")
        compare(ca.hslLightness, 0, "hslLight default 0")
    }

    // —— 核心契约：写 color → 四空间全同步（纯色端点量化精确）——
    function test_colorSetSynchronizesAllSpaces() {
        const ca = makeCA({ color: "#ff0000" })
        // RGB
        compare(ca.red, 255, "red 255")
        compare(ca.green, 0, "green 0")
        compare(ca.blue, 0, "blue 0")
        // HSV：纯红 h=0 s=255 v=255
        compare(ca.hsvHue, 0, "red hsvHue 0")
        compare(ca.hsvSaturation, 255, "red hsvSat 255")
        compare(ca.hsvValue, 255, "red hsvValue 255")
        // HSL：纯红 h=0 s=255 l=127（(max+min)/2 量化）
        compare(ca.hslHue, 0, "red hslHue 0")
        compare(ca.hslSaturation, 255, "red hslSat 255")
        compare(ca.hslLightness, 128, "red hslLight 128")
        // CMYK：纯红 c=0 m=255 y=255 k=0
        compare(ca.cyan, 0, "red cyan 0")
        compare(ca.magenta, 255, "red magenta 255")
        compare(ca.yellow, 255, "red yellow 255")
        compare(ca.black, 0, "red black 0")
        // 绿/蓝 hue 域
        const g = makeCA({ color: "#00ff00" })
        compare(g.hsvHue, 120, "green hsvHue 120")
        compare(g.hslHue, 120, "green hslHue 120")
        const b = makeCA({ color: "#0000ff" })
        compare(b.hsvHue, 240, "blue hsvHue 240")
        compare(b.hslHue, 240, "blue hslHue 240")
    }

    // —— 任一分量写 → 全空间重算（联动）——
    function test_componentWriteRecomputesSpaces() {
        const ca = makeCA({ color: "#ff0000" })
        // redF 0.5 → (0.5, 0, 0) 暗红（仅改 red）：HSV sat 保持 1（非灰）、
        // value 0.5、HSL lightness 0.25
        ca.redF = 0.5
        verify(fuzzy(ca.hsvSaturationF, 1), "dark red sat 1")
        verify(fuzzy(ca.hsvValueF, 0.5), "dark red value 0.5")
        verify(fuzzy(ca.hslLightnessF, 0.25), "dark red hslLight 0.25")
        // 再写 HSV value → RGB 联动
        ca.hsvValueF = 0.25
        verify(fuzzy(ca.redF, 0.25), "value 0.25 -> red 0.25")
        verify(fuzzy(ca.greenF, 0), "green stays 0")
    }

    // —— int/F 双轨同步（互写）——
    function test_intFloatDualTrackSync() {
        const ca = makeCA({ color: "#000000" })
        ca.red = 128
        // 128/255 = 0.50196… 量化回读
        verify(fuzzy(ca.redF, 128 / 255), "int write -> float track")
        ca.redF = 0.25
        compare(ca.red, 64, "float write -> int track")
        // hue 双轨
        ca.hsvHueF = 0.5
        compare(ca.hsvHue, 180, "hueF 0.5 -> hue 180")
        ca.hslHue = 90
        verify(fuzzy(ca.hslHueF, 0.25), "hue 90 -> hueF 0.25")
    }

    // —— 相等守卫：同值写入不广播（三级守卫）——
    function test_equalityGuardNoStorm() {
        const ca = makeCA({ color: "#ff0000" })
        const colorSpy = makeSpy(ca, "colorChanged")
        const redSpy = makeSpy(ca, "redChanged")
        const nameSpy = makeSpy(ca, "nameChanged")
        // 同色写入 → 无广播
        ca.color = "#ff0000"
        compare(colorSpy.count, 0, "same color -> no colorChanged")
        compare(nameSpy.count, 0, "same color -> no nameChanged")
        // 同分量写入 → 分量信号不触发
        ca.red = 255
        compare(redSpy.count, 0, "same red -> no redChanged")
        ca.redF = 1
        compare(redSpy.count, 0, "same redF -> no redChanged")
        // 真实变化仍广播（守卫不阻断有效写入）
        ca.red = 128
        compare(colorSpy.count, 1, "changed color -> colorChanged once")
        compare(redSpy.count, 1, "changed red -> redChanged once")
    }

    // —— 信号选择性广播：变的分量发射、未变的静默 ——
    function test_signalBroadcastSelective() {
        const ca = makeCA({ color: "#ff0000" })
        const colorSpy = makeSpy(ca, "colorChanged")
        const greenSpy = makeSpy(ca, "greenChanged")
        const redSpy = makeSpy(ca, "redChanged")
        const rgbaSpy = makeSpy(ca, "rgbaChanged")
        // 只改 red：redChanged + 列表/name/color 广播；green 静默
        ca.redF = 0.5
        compare(redSpy.count, 1, "red changed -> redChanged once")
        compare(greenSpy.count, 0, "green unchanged -> silent")
        compare(colorSpy.count, 1, "color changed -> colorChanged once")
        compare(rgbaSpy.count, 1, "color changed -> rgbaChanged once")
        // 灰（sat=0）→ 后续改 green 仍只广播 green 相关
        ca.greenF = 0.25
        compare(greenSpy.count, 1, "green changed -> greenChanged once")
        compare(redSpy.count, 1, "red unchanged -> silent")
    }

    // —— 列表属性：读 = 分量序列；写重建颜色 ——
    function test_listReadWrite() {
        const ca = makeCA({ color: "#ff0000" })
        compare(ca.rgba[0], 255, "rgba[0] = red")
        compare(ca.rgba[1], 0, "rgba[1] = green")
        compare(ca.rgba[3], 255, "rgba[3] = alpha")
        compare(ca.hsvF[0], 0, "hsvF[0] = hue 0")
        compare(ca.cmyk[1], 255, "cmyk[1] = magenta 255")
        // 写 rgba（int 含 a 位）
        ca.rgba = [10, 20, 30, 40]
        compare(ca.red, 10, "rgba write -> red")
        compare(ca.green, 20, "rgba write -> green")
        compare(ca.blue, 30, "rgba write -> blue")
        compare(ca.alpha, 40, "rgba write -> alpha")
        // 写 hsvF（重建颜色）
        ca.hsvF = [0.2, 0.5, 0.8]
        verify(fuzzy(ca.hsvHueF, 0.2), "hsvF write -> hue")
        verify(fuzzy(ca.hsvSaturationF, 0.5), "hsvF write -> sat")
        verify(fuzzy(ca.hsvValueF, 0.8), "hsvF write -> value")
        // 写 cmyk（int）：用可精确往返的端点值（CMYK→RGB→CMYK 往返量化，
        // 小分量在 RGB 中间转换中丢失——经 toCmyk 重算的 k 吸收）
        ca.cmyk = [0, 255, 255, 0]
        compare(ca.cyan, 0, "cmyk write -> cyan")
        compare(ca.magenta, 255, "cmyk write -> magenta")
        compare(ca.yellow, 255, "cmyk write -> yellow")
        compare(ca.black, 0, "cmyk write -> black")
        compare(ca.red, 255, "cmyk red -> red 255")
        compare(ca.green, 0, "cmyk red -> green 0")
        // 写 hslF
        ca.hslF = [0.5, 0.5, 0.5]
        verify(fuzzy(ca.hslHueF, 0.5), "hslF write -> hue")
        verify(fuzzy(ca.hslSaturationF, 0.5), "hslF write -> sat")
        verify(fuzzy(ca.hslLightnessF, 0.5), "hslF write -> light")
    }

    // —— 列表缺失条目用当前分量作默认 ——
    function test_listPartialWriteUsesDefaults() {
        const ca = makeCA({ color: "#ff0000" })
        ca.rgbaF = [0.5]
        verify(fuzzy(ca.redF, 0.5), "partial rgbaF -> red")
        verify(fuzzy(ca.greenF, 0), "green kept default")
        verify(fuzzy(ca.blueF, 0), "blue kept default")
        verify(fuzzy(ca.alphaF, 1), "alpha kept default")
        // hsvF 只给 hue → sat/value 用当前 toHsv 分量（红 sat=1 value=1）
        const c2 = makeCA({ color: "#ff0000" })
        c2.hsvF = [0.25]
        verify(fuzzy(c2.hsvHueF, 0.25), "partial hsvF -> hue")
        verify(fuzzy(c2.hsvSaturationF, 1), "sat kept")
        verify(fuzzy(c2.hsvValueF, 1), "value kept")
    }

    // —— 列表相等守卫：同列表写入不广播 ——
    function test_listEqualityGuard() {
        const ca = makeCA({ color: "#ff0000" })
        const spy = makeSpy(ca, "colorChanged")
        ca.rgba = [255, 0, 0, 255]
        compare(spy.count, 0, "same rgba -> silent")
        ca.hsvF = [0, 1, 1]
        compare(spy.count, 0, "same hsvF -> silent")
        ca.rgbaF = [1, 0, 0, 1]
        compare(spy.count, 0, "same rgbaF -> silent")
    }

    // —— 列表 alpha 语义（文档 Alpha semantics 节契约固定）——
    function test_listAlphaSemantics() {
        // 两路径统一保 alpha：分量写与无 a 位列表写都保留当前 alpha；
        // rgba/rgbaF 含 a 位，4 项列表写入即设置、短列表保留
        // （写入值须与当前列表不同——相等守卫提前 return 不重算）
        const ca = makeCA({ color: "#80ff0000" })
        verify(fuzzy(ca.alphaF, 128 / 255), "seed semi-transparent")
        ca.cmykF = [0.1, 0.2, 0.3, 0.4]
        verify(fuzzy(ca.alphaF, 128 / 255), "cmykF write preserves alpha")
        ca.color = "#80ff0000"
        ca.hsvF = [0.5, 1, 1]
        verify(fuzzy(ca.alphaF, 128 / 255), "hsvF write preserves alpha")
        ca.color = "#80ff0000"
        ca.hslF = [0.2, 1, 0.5]
        verify(fuzzy(ca.alphaF, 128 / 255), "hslF write preserves alpha")
        ca.color = "#80ff0000"
        ca.cmyk = [10, 255, 255, 0]
        verify(fuzzy(ca.alphaF, 128 / 255), "cmyk write preserves alpha")
        ca.color = "#80ff0000"
        ca.hsv = [60, 255, 255]
        verify(fuzzy(ca.alphaF, 128 / 255), "hsv write preserves alpha")
        ca.color = "#80ff0000"
        ca.hsl = [30, 255, 127]
        verify(fuzzy(ca.alphaF, 128 / 255), "hsl write preserves alpha")
        // rgbaF 含 a 位：4 项列表写入即设置
        ca.color = "#80ff0000"
        ca.rgbaF = [1, 0, 0, 0.25]
        verify(fuzzy(ca.alphaF, 0.25), "rgbaF write sets alpha")
    }

    // —— 零 alpha 保通道（文档 Zero-alpha channel retention 节）——
    // alpha 写 0（双轨 + 列表 a 位）仅透明不丢 RGB；恢复 alpha 还原
    // 原色；全透明态 solidColor/name 仍报通道。name 串为探针实证的
    // 精确值；F 轨分量用 fuzzy（文件头量化容差论证）。
    function test_alphaZeroChannelRetention() {
        const ca = makeCA({ color: Qt.rgba(0.2, 0.3, 0.5, 1) })
        // F 轨：alphaF 0 -> 1 往返
        ca.alphaF = 0
        verify(ca.isValid(), "alpha zero stays valid")
        verify(fuzzy(ca.redF, 0.2), "alphaF=0 keeps red")
        verify(fuzzy(ca.greenF, 0.3), "alphaF=0 keeps green")
        verify(fuzzy(ca.blueF, 0.5), "alphaF=0 keeps blue")
        compare(ca.name, "#00334d80", "name reports channels in argb")
        ca.alphaF = 1
        verify(fuzzy(ca.redF, 0.2), "restore keeps red")
        verify(fuzzy(ca.greenF, 0.3), "restore keeps green")
        verify(fuzzy(ca.blueF, 0.5), "restore keeps blue")
        compare(ca.name, "#334d80", "restored opaque name")
        // int 轨：alpha 0 -> 255 往返
        ca.color = Qt.rgba(0.2, 0.3, 0.5, 1)
        ca.alpha = 0
        verify(fuzzy(ca.redF, 0.2), "int alpha=0 keeps red")
        verify(fuzzy(ca.blueF, 0.5), "int alpha=0 keeps blue")
        ca.alpha = 255
        compare(ca.name, "#334d80", "int track restores color")
        // 列表 a 位写 0 同样保通道，恢复 a 位即还原
        ca.rgbaF = [0.2, 0.3, 0.5, 0]
        verify(fuzzy(ca.greenF, 0.3), "list alpha slot keeps channels")
        ca.rgbaF = [0.2, 0.3, 0.5, 1]
        compare(ca.name, "#334d80", "list restore color")
        // 全透明态派生面：solidColor 直接取回不透明通道
        ca.color = Qt.rgba(0.2, 0.3, 0.5, 1)
        ca.alphaF = 0
        const s = ca.solidColor
        verify(fuzzy(s.r, 0.2) && fuzzy(s.g, 0.3) && fuzzy(s.b, 0.5),
               "solidColor recovers channels while transparent")
        compare(s.a, 1, "solidColor opaque")
        // 输入侧语义锁定：字面量 transparent 解析即全零（输入语义，
        // 非对象行为），此后恢复 alpha 得黑
        ca.color = "transparent"
        verify(fuzzy(ca.redF, 0) && fuzzy(ca.blueF, 0),
               "literal transparent parses to zero channels")
        ca.alphaF = 1
        compare(ca.name, "#000000", "transparent then opaque is black")
    }

    // —— 跨空间一致性：color 入口写多种子色，四空间重建线全部指向同一颜色 ——
    function test_crossSpaceConsistency() {
        const seeds = ["#ff0000", "#00ff00", "#0000ff", "#808080", "#123456",
                       "#80ff0000", "#f0f0f0", "#000000", "#ffffff"]
        for (let i = 0; i < seeds.length; i++) {
            const ca = makeCA({ color: seeds[i] })
            verifyConsistent(ca, "seed " + seeds[i])
        }
    }

    // —— 连续变化跟随：全入口类型依次变化，每步后四空间保持一致 ——
    function test_continuousCrossSpaceFollow() {
        const ca = makeCA({ color: "#123456" })
        const steps = [
            { name: "red int", run: () => { ca.red = 200 } },
            { name: "greenF", run: () => { ca.greenF = 0.7 } },
            { name: "hsvHue int", run: () => { ca.hsvHue = 100 } },
            { name: "hsvSatF", run: () => { ca.hsvSaturationF = 0.9 } },
            { name: "hslLight int", run: () => { ca.hslLightness = 180 } },
            { name: "cyan int", run: () => { ca.cyan = 20 } },
            { name: "blackF", run: () => { ca.blackF = 0.3 } },
            { name: "alpha int", run: () => { ca.alpha = 128 } },
            { name: "color", run: () => { ca.color = "#ff8040" } },
            { name: "rgbaF list", run: () => { ca.rgbaF = [0.1, 0.2, 0.3, 0.8] } },
            { name: "hsvF list", run: () => { ca.hsvF = [0.4, 0.6, 0.7] } },
            { name: "hsl int list", run: () => { ca.hsl = [90, 200, 150] } },
            { name: "cmykF list", run: () => { ca.cmykF = [0.2, 0.3, 0.4, 0.1] } },
            { name: "name", run: () => { ca.name = "#a1b2c3" } },
        ]
        for (let i = 0; i < steps.length; i++) {
            steps[i].run()
            verifyConsistent(ca, "step " + i + " " + steps[i].name)
        }
    }

    // —— name 读：#RRGGBB（不透明）/ #AARRGGBB（alphaF<1）——
    function test_nameReadWrite() {
        const ca = makeCA({ color: "#ff0000" })
        compare(ca.name, "#ff0000", "opaque name hex")
        ca.alpha = 128
        compare(ca.name, "#80ff0000", "semi name argb")
        ca.alpha = 255
        compare(ca.name, "#ff0000", "opaque back to rgb")
        // 写 name：hex 与色名都解析生效
        ca.name = "#00ff80"
        compare(ca.red, 0, "name write -> red")
        compare(ca.green, 255, "name write -> green")
        compare(ca.blue, 128, "name write -> blue")
        ca.name = "red"
        compare(ca.red, 255, "color name write -> red 255")
        compare(ca.green, 0, "color name write -> green 0")
    }

    // —— name 非法写 → 颜色无效 ——
    function test_nameInvalidWrite() {
        const ca = makeCA({ color: "#ff0000" })
        ca.name = "notacolor"
        verify(!ca.isValid(), "unparseable name -> invalid color")
    }

    // —— 派生只读：solidColor（alpha 强制 1）——
    function test_derivedSolidColor() {
        const ca = makeCA({ color: "#80ff0000" })
        compare(ca.solidColor.a, 1, "solidColor alpha 1")
        compare(ca.solidColor.r, 1, "solidColor red kept")
        compare(ca.solidColor.g, 0, "solidColor green kept")
    }

    // —— 派生只读：visualBrightness（0.299/0.587/0.114 加权）——
    function test_visualBrightness() {
        const w = makeCA({ color: "#ffffff" })
        verify(fuzzy(w.visualBrightness, 1), "white -> 1")
        const k = makeCA({ color: "#000000" })
        verify(fuzzy(k.visualBrightness, 0), "black -> 0")
        const r = makeCA({ color: "#ff0000" })
        verify(fuzzy(r.visualBrightness, 0.299), "red -> 0.299")
        const g = makeCA({ color: "#808080" })
        verify(fuzzy(g.visualBrightness, 128 / 255), "grey -> 128/255")
    }

    // —— 派生只读：recommendedForegroundColor（0.5 阈值含边界）——
    function test_recommendedForeground() {
        const w = makeCA({ color: "#ffffff" })
        compare(w.recommendedForegroundColor, "#000000", "white -> black")
        const k = makeCA({ color: "#000000" })
        compare(k.recommendedForegroundColor, "#ffffff", "black -> white")
        // 边界：#808080 亮度 0.502 ≥ 0.5 → 黑；#7f7f7f 亮度 0.498 < 0.5 → 白
        const hi = makeCA({ color: "#808080" })
        compare(hi.recommendedForegroundColor, "#000000", "brightness 0.502 -> black")
        const lo = makeCA({ color: "#7f7f7f" })
        compare(lo.recommendedForegroundColor, "#ffffff", "brightness 0.498 -> white")
    }

    // —— 静态方法：hex ——
    function test_staticHex() {
        // static Q_INVOKABLE 经实例调用（类型名无方法面，探针实证）
        const ca = makeCA({})
        compare(ca.hex(255), "ff", "hex 255")
        compare(ca.hex(0), "0", "hex 0")
        compare(ca.hex(15), "f", "hex 15")
        compare(ca.hex(4660), "1234", "hex 4660")
    }

    // —— 静态方法：isValidName（格式面全覆盖）——
    function test_staticIsValidName() {
        const ca = makeCA({})
        verify(ca.isValidName("red"), "svg color name")
        verify(ca.isValidName("#ff0000"), "rrggbb")
        verify(ca.isValidName("#fff"), "rgb short")
        verify(ca.isValidName("#aabbccdd"), "aarrggbb")
        verify(ca.isValidName("#123456789"), "rrrgggbbb 9-digit")
        verify(ca.isValidName("#112233445566"), "rrrrggggbbbb 12-digit")
        verify(ca.isValidName("transparent"), "transparent")
        verify(!ca.isValidName("notacolor"), "garbage")
        verify(!ca.isValidName("#gg0000"), "bad hex digit")
        verify(!ca.isValidName("#12345"), "bad hex length")
        verify(!ca.isValidName(""), "empty")
    }

    // —— 静态方法：isValid（未设色 false / 设色 true / 非法 name false）——
    function test_staticIsValid() {
        const ca = makeCA({})
        verify(!ca.isValid(), "fresh invalid")
        ca.color = "#336699"
        verify(ca.isValid(), "after color set valid")
        ca.name = "garbage"
        verify(!ca.isValid(), "after bad name invalid again")
    }

    // —— 边界：灰色 hue=-1（无彩色 marker），fresh 隔离 ——
    function test_hueAchromatic() {
        const grey = makeCA({ color: "#808080" })
        compare(grey.hsvHue, -1, "grey hsvHue -1")
        compare(grey.hslHue, -1, "grey hslHue -1")
        verify(fuzzy(grey.hsvHueF, -1), "grey hsvHueF -1")
        verify(fuzzy(grey.hslHueF, -1), "grey hslHueF -1")
        // 有彩色 hue 正常（fresh 组件，不掺灰场景）
        const red = makeCA({ color: "#ff0000" })
        compare(red.hsvHue, 0, "red hue 0")
        compare(red.hslHue, 0, "red hslHue 0")
    }

    // —— 边界：hue 越界强制进范围（int 轨 wrap，360→0、540→180）——
    // 注：F 轨 hue 越界（如 hsvHueF=1.5）经 QColor 参数域检查产生 Invalid
    // 色（非 wrap）——不在本测试固定，见文档「Invalid colors」节。
    function test_hueWrap() {
        // fresh 有彩色组件（灰色 hue 写入无效）
        const ca = makeCA({ color: "#ff0000" })
        ca.hsvHue = 360
        compare(ca.hsvHue, 0, "hsvHue 360 -> 0")
        ca.hslHue = 540
        compare(ca.hslHue, 180, "hslHue 540 -> 180")
        ca.hslHue = 720
        compare(ca.hslHue, 0, "hslHue 720 -> 0")
    }

    // —— 边界：RGB F 轨越界 clamp [0,1]（ExtendedRgb → toRgb 收敛）——
    // 注：HSV/HSL/CMYK 分量越界写入经 QColor 参数域检查产生 Invalid 色
    // （文档「Invalid colors」节），非 clamp——不在本测试固定。
    function test_clampOutOfRange() {
        const ca = makeCA({ color: "#ff0000" })
        ca.redF = 1.5
        verify(fuzzy(ca.redF, 1), "redF 1.5 -> 1")
        ca.greenF = -0.5
        verify(fuzzy(ca.greenF, 0), "greenF -0.5 -> 0")
        ca.blueF = 1.2
        verify(fuzzy(ca.blueF, 1), "blueF 1.2 -> 1")
    }

    // —— QML 扩展：Channels 枚举与通道元数据 ——
    function test_channelLiterals() {
        compare(ColorAssistant.Channels.Alpha, 0, "Alpha 0")
        compare(ColorAssistant.Channels.Red, 1, "Red 1")
        compare(ColorAssistant.Channels.Green, 2, "Green 2")
        compare(ColorAssistant.Channels.Blue, 3, "Blue 3")
        compare(ColorAssistant.Channels.HSVHue, 4, "HSVHue 4")
        compare(ColorAssistant.Channels.HSLHue, 7, "HSLHue 7")
        compare(ColorAssistant.Channels.Cyan, 10, "Cyan 10")
        compare(ColorAssistant.Channels.Black, 13, "Black 13")
        // QML_EXTENDED 的 static 方法经实例调用（类型名仅暴露枚举）
        const ca = makeCA({})
        compare(ca.channelName(ColorAssistant.Channels.Red), "red",
               "channelName red")
        compare(ca.channelName(ColorAssistant.Channels.HSVHue),
               "hsvHue", "channelName hsvHue")
        compare(ca.channelNameF(ColorAssistant.Channels.Red),
               "redF", "channelNameF redF")
        compare(ca.channelTag(ColorAssistant.Channels.Red), "RED",
               "channelTag RED")
        compare(ca.channelTagShort(ColorAssistant.Channels.Red),
               "RED", "channelTagShort RED")
        compare(ca.channelTagShort(
                    ColorAssistant.Channels.HSLSaturation), "SAT",
               "channelTagShort SAT")
        compare(ca.channelTagShort(ColorAssistant.Channels.Black),
               "BLAK", "channelTagShort BLAK")
        compare(ca.channelColor(ColorAssistant.Channels.Red),
               "#ff0000", "channelColor red")
        compare(ca.channelColor(ColorAssistant.Channels.Alpha),
               "#a0a0a4", "channelColor alpha grey")
        compare(ca.channelColor(ColorAssistant.Channels.HSVHue),
               "#00000000", "channelColor hue transparent")
    }

    // —— QML 扩展：formatChannelNumberFloat 四种输出 ——
    function test_literalFormat() {
        const ca = makeCA({})
        compare(ca.formatChannelNumberFloat(0), "0", "0")
        compare(ca.formatChannelNumberFloat(1), "1", "1")
        compare(ca.formatChannelNumberFloat(0.5), ".500", ".500")
        compare(ca.formatChannelNumberFloat(0.1234), ".123", ".123")
        compare(ca.formatChannelNumberFloat(0.9996), "1",
               "round up to 1")
        compare(ca.formatChannelNumberFloat(0.0004), "0",
               "round down to 0")
        compare(ca.formatChannelNumberFloat(NaN), "NaN", "NaN")
    }

    // —— QML 扩展：parseChannelNumberFloat（format 反向）——
    function test_literalParse() {
        const ca = makeCA({})
        verify(fuzzy(ca.parseChannelNumberFloat("0.5"), 0.5),
               "parse 0.5")
        verify(fuzzy(ca.parseChannelNumberFloat("350"), 0.35),
               "parse int -> leading dot")
        verify(fuzzy(ca.parseChannelNumberFloat("1.2.3"), 1.23),
               "parse second dot dropped")
        verify(fuzzy(ca.parseChannelNumberFloat(".5"), 0.5),
               "parse leading dot")
        verify(isNaN(ca.parseChannelNumberFloat("abc")),
               "parse garbage -> NaN")
        // 往返：format 输出可解析回原值
        verify(fuzzy(ca.parseChannelNumberFloat(
                         ca.formatChannelNumberFloat(0.5)), 0.5),
               "format -> parse roundtrip")
    }

    // —— QML 扩展：clampChannelRange ——
    function test_literalClampRange() {
        const ca = makeCA({})
        compare(ca.clampChannelRange(-0.5), 0, "lower clamp")
        compare(ca.clampChannelRange(1.5), 1, "upper clamp")
        compare(ca.clampChannelRange(0.5), 0.5, "mid pass")
    }
    // —— 越界：RGB/alpha 分量双轨 clamp（文档 Out-of-range 第 1 条）——
    // 期望值全部为端点（0/1/255）——量化精确，int 轨精确断言、F 轨端点
    // fuzzy（文件头容差论证）。种子取中程有彩色，clamp 后必为实质变化。
    function test_outOfRangeComponentClamp() {
        const clamps = [
            ["redF", 1.5], ["redF", -0.5], ["greenF", 1.2], ["greenF", -0.5],
            ["blueF", 1.5], ["blueF", -0.2],
            ["alphaF", 1.5], ["alphaF", -0.5],
            ["red", 300], ["red", -10], ["green", 300], ["green", -10],
            ["blue", 300], ["blue", -10], ["alpha", 300], ["alpha", -10]
        ]
        const bounds = { redF: [0, 1], greenF: [0, 1], blueF: [0, 1],
                         alphaF: [0, 1], red: [0, 255], green: [0, 255],
                         blue: [0, 255], alpha: [0, 255] }
        for (let i = 0; i < clamps.length; i++) {
            const prop = clamps[i][0]
            const ca = makeCA({ color: "#4080c0" })
            ca[prop] = clamps[i][1]
            verify(ca.isValid(), prop + " clamp keeps valid")
            const lo = bounds[prop][0]
            const expect = clamps[i][1] < 0 ? lo : bounds[prop][1]
            if (typeof expect === "number" && prop.endsWith("F"))
                verify(fuzzy(ca[prop], expect),
                       prop + "=" + clamps[i][1] + " -> " + expect)
            else
                compare(ca[prop], expect,
                        prop + "=" + clamps[i][1] + " -> " + expect)
        }
    }

    // —— 越界：HSV/HSL/CMYK 双轨非 hue 分量与 F hue → Invalid；列表入口
    // 全部 → Invalid（含 hue 位——列表无 wrap 语义；rgba int 列表同）——
    // 文档 Out-of-range 第 2、3 条。Invalid 破坏分量状态，每例 fresh 实例。
    function test_outOfRangeInvalid() {
        const cases = [
            ["hsvHueF", 1.5], ["hsvHueF", -0.5],
            ["hsvSaturationF", 1.2], ["hsvValueF", -0.5],
            ["hslHueF", 1.5], ["hslHueF", -0.5],
            ["hslSaturationF", -0.5], ["hslLightnessF", 1.2],
            ["cyanF", 1.5], ["magentaF", 1.2], ["yellowF", -0.3],
            ["blackF", -0.5],
            ["hsvSaturation", 300], ["hsvValue", -10],
            ["hslSaturation", 300], ["hslLightness", -10],
            ["cyan", 300], ["magenta", -10], ["yellow", 300], ["black", 300],
            ["rgba", [-10, 0, 0, 255]], ["rgba", [300, 0, 0, 255]],
            ["hsv", [400, 255, 255]], ["hsv", [0, 300, 0]],
            ["hsl", [400, 0, 127]], ["cmyk", [0, 0, 0, 300]],
            ["hsvF", [1.5, 1, 1]], ["hslF", [0.5, -0.5, 0.5]],
            ["cmykF", [0.5, 0.5, 0.5, 1.5]]
        ]
        for (let i = 0; i < cases.length; i++) {
            const ca = makeCA({ color: "#ff0000" })
            ca[cases[i][0]] = cases[i][1]
            verify(!ca.isValid(),
                   cases[i][0] + "=" + cases[i][1] + " -> invalid")
        }
    }

    // —— 越界：rgbaF 浮点列表接受扩展值（文档 Out-of-range 列表条目第 2
    // 款）：颜色保持有效，分量视图收敛回 [0,1]（探针实证：写 [1.5,0,0,1]
    // 后 isValid=true、redF 读 1.0）——
    function test_listFloatExtendedRgb() {
        const ca = makeCA({ color: "#ff0000" })
        ca.rgbaF = [1.5, 0, 0, 1]
        verify(ca.isValid(), "extended rgb stays valid")
        verify(fuzzy(ca.redF, 1), "redF view converged to 1")
        verify(fuzzy(ca.rgbaF[0], 1), "rgbaF readback converged")
        const cb = makeCA({ color: "#00ff00" })
        cb.rgbaF = [0, -0.5, 0, 1]
        verify(cb.isValid(), "negative extended stays valid")
        verify(fuzzy(cb.greenF, 0), "greenF view converged to 0")
    }

    // —— 恢复：Invalid 后任一入口合法写恢复有效（文档 Out-of-range 收尾句）——
    function test_recoverAfterInvalidWrite() {
        const ca = makeCA({ color: "#ff0000" })
        ca.hsvSaturation = 300
        verify(!ca.isValid(), "invalid after out-of-range")
        ca.green = 128
        verify(ca.isValid(), "valid again after in-range write")
        compare(ca.green, 128, "recovery value applied")
    }

    // —— 信号守卫全通道：每个可写属性同值重写 → 各自 Changed 计数 0 ——
    // 覆盖 color + name + 28 分量 + 8 列表全部可写入口（派生只读不可写，
    // 其通知面即 colorChanged，由 color 条目覆盖）。种子取中程有彩色，
    // 所有空间分量非退化。同值重写为同步 no-op，计数立即可断言。
    function test_guardAllWritablePropertiesNoRepeat() {
        const ca = makeCA({ color: "#4080c0" })
        const props = [
            "color", "name",
            "redF", "greenF", "blueF", "alphaF",
            "cyanF", "magentaF", "yellowF", "blackF",
            "hsvHueF", "hsvSaturationF", "hsvValueF",
            "hslHueF", "hslSaturationF", "hslLightnessF",
            "red", "green", "blue", "alpha",
            "cyan", "magenta", "yellow", "black",
            "hsvHue", "hsvSaturation", "hsvValue",
            "hslHue", "hslSaturation", "hslLightness",
            "rgbaF", "cmykF", "hsvF", "hslF",
            "rgba", "cmyk", "hsv", "hsl"
        ]
        for (let i = 0; i < props.length; i++) {
            const prop = props[i]
            const spy = makeSpy(ca, prop + "Changed")
            ca[prop] = ca[prop]
            compare(spy.count, 0, prop + " same-value rewrite silent")
        }
    }

    // —— 正触发全通道：每个可写属性一次实质变化 → 各自 Changed 恰好 1 ——
    // 每属性 fresh 实例（互不干扰），写入值均异于 "#4080c0" 种子派生值。
    function test_allWritablePropertiesBroadcastOnChange() {
        const changes = [
            ["color", "#123456"], ["name", "#345678"],
            ["redF", 0.9], ["greenF", 0.8], ["blueF", 0.2], ["alphaF", 0.5],
            ["cyanF", 0.9], ["magentaF", 0.1], ["yellowF", 0.9],
            ["blackF", 0.1],
            ["hsvHueF", 0.3], ["hsvSaturationF", 0.4], ["hsvValueF", 0.6],
            ["hslHueF", 0.3], ["hslSaturationF", 0.4], ["hslLightnessF", 0.6],
            ["red", 200], ["green", 40], ["blue", 100], ["alpha", 128],
            ["cyan", 200], ["magenta", 50], ["yellow", 200], ["black", 50],
            ["hsvHue", 100], ["hsvSaturation", 200], ["hsvValue", 150],
            ["hslHue", 100], ["hslSaturation", 200], ["hslLightness", 150],
            ["rgbaF", [0.9, 0.7, 0.5, 0.3]],
            ["cmykF", [0.2, 0.3, 0.4, 0.1]],
            ["hsvF", [0.3, 0.4, 0.6]], ["hslF", [0.3, 0.4, 0.6]],
            ["rgba", [90, 70, 50, 30]], ["cmyk", [20, 30, 40, 10]],
            ["hsv", [100, 200, 150]], ["hsl", [100, 200, 150]]
        ]
        for (let i = 0; i < changes.length; i++) {
            const prop = changes[i][0]
            const ca = makeCA({ color: "#4080c0" })
            const spy = makeSpy(ca, prop + "Changed")
            ca[prop] = changes[i][1]
            compare(spy.count, 1,
                    prop + " real change broadcasts once")
        }
    }

    // —— 单维变化不滥发矩阵：空间内未变分量的 Changed 静默、
    // 列表/name/color 无条件广播（文档 Signals 节语义）——
    // 四个单维场景：HSV value、HSL lightness、alpha、hue。
    function test_broadcastSingleDimensionSilence() {
        // 场景 1：改 HSV value（红 v 1 -> 0.5）——HSV 空间内 hue/sat 不变
        {
            const ca = makeCA({ color: "#ff0000" })
            const silent = ["hsvHue", "hsvHueF", "hsvSaturation",
                            "hsvSaturationF"]
            for (let i = 0; i < silent.length; i++) {
                const spy = makeSpy(ca, silent[i] + "Changed")
                ca.hsvValueF = 0.5
                compare(spy.count, 0,
                        "value write keeps " + silent[i] + " silent")
            }
        }
        // 场景 2：改 HSL lightness（l -> 0.25）——HSL 空间内 hue/sat 不变
        {
            const ca = makeCA({ color: "#ff0000" })
            const silent = ["hslHue", "hslHueF", "hslSaturation",
                            "hslSaturationF"]
            for (let i = 0; i < silent.length; i++) {
                const spy = makeSpy(ca, silent[i] + "Changed")
                ca.hslLightnessF = 0.25
                compare(spy.count, 0,
                        "lightness write keeps " + silent[i] + " silent")
            }
        }
        // 场景 3：改 alpha——26 个彩色分量全部静默（alpha 不参与色彩
        // 空间换算）；列表/name/color 无条件广播照发（锁定 cmyk 值不变
        // 但 cmykChanged 照发的无条件广播语义）
        {
            const ca = makeCA({ color: "#ff0000" })
            const chromatic = [
                "redF", "greenF", "blueF",
                "cyanF", "magentaF", "yellowF", "blackF",
                "hsvHueF", "hsvSaturationF", "hsvValueF",
                "hslHueF", "hslSaturationF", "hslLightnessF",
                "red", "green", "blue",
                "cyan", "magenta", "yellow", "black",
                "hsvHue", "hsvSaturation", "hsvValue",
                "hslHue", "hslSaturation", "hslLightness"
            ]
            const spies = []
            for (let i = 0; i < chromatic.length; i++)
                spies.push([chromatic[i], makeSpy(ca, chromatic[i] + "Changed")])
            const fired = []
            const firedNames = ["color", "name", "rgba", "rgbaF",
                                "cmyk", "hsv", "hsl", "alpha", "alphaF"]
            for (let i = 0; i < firedNames.length; i++)
                fired.push([firedNames[i], makeSpy(ca, firedNames[i] + "Changed")])
            ca.alpha = 128
            for (let i = 0; i < spies.length; i++)
                compare(spies[i][1].count, 0,
                        "alpha write keeps " + spies[i][0] + " silent")
            for (let i = 0; i < fired.length; i++)
                compare(fired[i][1].count, 1,
                        "alpha write fires " + fired[i][0] + " once")
        }
        // 场景 4：hue 0 -> 60（红 -> 黄）——RGB 端 red/blue 不变、CMYK 端
        // cyan/yellow/black 不变、HSV sat/v 与 HSL sat/l 不变，全部静默；
        // green/magenta/hue 双轨触发
        {
            const ca = makeCA({ color: "#ff0000" })
            const silent = [
                "red", "redF", "blue", "blueF",
                "cyan", "cyanF", "yellow", "yellowF", "black", "blackF",
                "hsvSaturation", "hsvSaturationF", "hsvValue", "hsvValueF",
                "hslSaturation", "hslSaturationF", "hslLightness",
                "hslLightnessF"
            ]
            const spies = []
            for (let i = 0; i < silent.length; i++)
                spies.push([silent[i], makeSpy(ca, silent[i] + "Changed")])
            const changed = ["green", "greenF", "magenta", "magentaF",
                             "hsvHue", "hsvHueF", "hslHue", "hslHueF"]
            const changedSpies = []
            for (let i = 0; i < changed.length; i++)
                changedSpies.push([changed[i], makeSpy(ca, changed[i] + "Changed")])
            ca.hsvHue = 60
            for (let i = 0; i < spies.length; i++)
                compare(spies[i][1].count, 0,
                        "hue write keeps " + spies[i][0] + " silent")
            for (let i = 0; i < changedSpies.length; i++)
                compare(changedSpies[i][1].count, 1,
                        "hue write fires " + changedSpies[i][0] + " once")
        }
    }

    // —— 高负载确定性：多入口交错高频写，每轮四空间一致（有序传播
    // 无撕裂）——120 轮覆盖 6 类入口（分量 int/F、列表、color、name），
    // 写入值均为轮次确定性函数。
    function test_highLoadInterleavedWritesStayConsistent() {
        const hex2 = function(n) {
            return ("0" + n.toString(16)).slice(-2)
        }
        const ca = makeCA({ color: "#4080c0" })
        for (let i = 0; i < 120; i++) {
            switch (i % 6) {
                case 0: ca.redF = ((i * 13) % 100) / 100; break
                case 1: ca.hsvHueF = (i % 12) / 12; break
                case 2: ca.hslLightnessF = ((i * 7) % 100) / 100; break
                case 3: ca.cyan = (i * 11) % 255; break
                case 4:
                    ca.rgbaF = [((i * 3) % 10) / 10, ((i * 5) % 10) / 10,
                                ((i * 7) % 10) / 10, 1]
                    break
                case 5:
                    ca.name = "#" + hex2((i * 37) % 256) + hex2((i * 59) % 256)
                              + hex2((i * 91) % 256)
                    break
            }
            verifyConsistent(ca, "interleave " + i)
        }
        verify(ca.isValid(), "still valid after 120 interleaved writes")
    }

    // —— 高负载确定性：绑定消费——消费对象绑定 color 与
    // visualBrightness，高频写入期间绑定即时跟随，最终收敛一致。
    function test_bindingConsumersFollowUnderLoad() {
        const hex2 = function(n) {
            return ("0" + n.toString(16)).slice(-2)
        }
        const ca = makeCA({ color: "#4080c0" })
        const consumer = createTemporaryQmlObject(
            'import QtQuick; Item { property color observed: "black";'
            + ' property real lum: 0 }', root)
        consumer.observed = Qt.binding(function() { return ca.color })
        consumer.lum = Qt.binding(function() { return ca.visualBrightness })
        for (let i = 0; i < 60; i++) {
            if (i % 2 === 0)
                ca.color = Qt.rgba(((i * 37) % 256) / 255,
                                   ((i * 59) % 256) / 255,
                                   ((i * 91) % 256) / 255, 1)
            else
                ca.name = "#" + hex2((i * 37) % 256) + hex2((i * 59) % 256)
                          + hex2((i * 91) % 256)
            compare(consumer.observed, ca.color,
                    "binding follows color at " + i)
            verify(fuzzy(consumer.lum, ca.visualBrightness),
                   "binding follows brightness at " + i)
        }
    }

    // —— 高负载确定性：重入安全——回声对象绑定 color，处理器把同值
    // 写回 assistant（模拟双向绑定环）：guard 拦截回写，每次实质外部
    // 写恰好一次 colorChanged，无风暴无栈溢出。
    function test_reentrantWritebackConverges() {
        const ca = makeCA({ color: "#ff0000" })
        const echo = createTemporaryQmlObject(
            'import QtQuick; Item { property color c: "black" }', root)
        echo.c = Qt.binding(function() { return ca.color })
        echo.cChanged.connect(function() { ca.color = echo.c })
        const spy = makeSpy(ca, "colorChanged")
        ca.color = "#00ff00"
        compare(spy.count, 1, "reentrant same-value writeback guarded")
        for (let i = 0; i < 50; i++)
            ca.color = Qt.rgba(((i * 37) % 256) / 255,
                               ((i * 59) % 256) / 255,
                               ((i * 91) % 256) / 255, 1)
        compare(spy.count, 51, "one emission per real write under reentry")
        verify(ca.isValid(), "valid after reentrant load")
    }
}
