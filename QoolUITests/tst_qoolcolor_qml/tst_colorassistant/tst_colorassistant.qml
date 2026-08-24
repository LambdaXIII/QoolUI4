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
// - 列表 alpha 语义：rgba/rgbaF 含 a 位；cmyk/cmykF/hsv/hsvF/hslF 写入
//   重置 alpha 为不透明；hsl（int 轨）保留 alpha
// - name：不透明 #RRGGBB / 半透明 #AARRGGBB（alphaF<1 判定）；写解析
//   生效；非法串 → 颜色无效（isValid()=false）
// - 派生只读：solidColor（alpha 强制 1）、visualBrightness（0.299/0.587/
//   0.114 加权）、recommendedForegroundColor（0.5 阈值：≥0.5 黑否则白）
// - 静态方法：hex/isValidName/isValid
// - 边界：灰色 hue=-1（无彩色 marker）；hue int 轨越界强制进范围（360→0、
//   540→180）；RGB F 轨越界 clamp [0,1]（ExtendedRgb → toRgb）；HSV/HSL/
//   CMYK 分量越界 → 颜色无效（QColor 参数域，见文档 Invalid colors）
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
        // cmyk/hsv/hslF 列表写入重置 alpha 为不透明
        // （写入值须与当前列表不同——相等守卫提前 return 不重算）
        const ca = makeCA({ color: "#80ff0000" })
        verify(fuzzy(ca.alphaF, 128 / 255), "seed semi-transparent")
        ca.cmykF = [0.1, 0.2, 0.3, 0.4]
        verify(fuzzy(ca.alphaF, 1), "cmykF write resets alpha")
        ca.color = "#80ff0000"
        ca.hsvF = [0.5, 1, 1]
        verify(fuzzy(ca.alphaF, 1), "hsvF write resets alpha")
        ca.color = "#80ff0000"
        ca.hslF = [0.2, 1, 0.5]
        verify(fuzzy(ca.alphaF, 1), "hslF write resets alpha")
        ca.color = "#80ff0000"
        ca.cmyk = [10, 255, 255, 0]
        verify(fuzzy(ca.alphaF, 1), "cmyk write resets alpha")
        ca.color = "#80ff0000"
        ca.hsv = [60, 255, 255]
        verify(fuzzy(ca.alphaF, 1), "hsv write resets alpha")
        // hsl（int 轨）特例：保留 alpha
        ca.color = "#80ff0000"
        ca.hsl = [30, 255, 127]
        verify(fuzzy(ca.alphaF, 128 / 255), "hsl write preserves alpha")
        // rgbaF 含 a 位：写入即设置
        ca.color = "#80ff0000"
        ca.rgbaF = [1, 0, 0, 0.25]
        verify(fuzzy(ca.alphaF, 0.25), "rgbaF write sets alpha")
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
}
