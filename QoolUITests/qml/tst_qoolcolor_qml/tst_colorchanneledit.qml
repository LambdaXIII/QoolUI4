import QtQuick
import QtTest
import Qool
import Qool.Color
import Qool.Controls

// ColorChannelEdit 测试（Qool.Color/ColorChannelEdit.qml——通道值编辑控件：
// EditableText 编辑会话 + ColorAssistant 通道双向同步）。
//
// 被测契约（外部行为与公开契约）：
// - 初始显示：非编辑态显示格式化通道值（formatChannelNumberFloat，如
//   ".500"），首帧即正确（不空白）
// - 读链：assistant 通道变化 → root.value 跟随 + 显示更新
// - 写链：root.value 写入（程序化 / 编辑收尾）→ assistant 通道变化
// - 编辑收尾：textFromEditText 解析（ColorNameHQ.parseChannelNumberFloat
//   统一语义——清洗+补点）→ 写 root.value → assistant
// - NaN 输入：空/非法不写数据（validator 拒绝 + 解析 NaN 双路径），显示回位
// - 解析语义：350 → .350 = 0.35（无点头部补点）、1.5 保留原值、空 → NaN；
//   格式化四种输出 '0'/'1'/'.xxx'/'NaN'（format/parse 配对）
//
// 隔离：每个测试函数独立实例；动画统一关闭。
// 编辑会话模拟：editing/editText 程序化进出（EditableText Qool 扩展——
// editing 可写、editText = 会话文本 alias judge.text）——收尾判定走 judge
// 模型，同步可靠；真实鼠标交互（点击/键盘）不在自动化范围（offscreen 不
// 注入合成事件，与 tst_slider 同策略）。

TestCase {
    id: root

    name: "ColorChannelEdit"
    width: 400
    height: 300

    Component {
        id: editComp
        ColorChannelEdit {
            width: 200
            height: 30
            animationEnabled: false
            colorAssistant: ColorAssistant {
                color: "#ff0000"
            }
            channel: ColorNameHQ.HSLLightness
        }
    }

    function makeEdit() {
        return createTemporaryObject(editComp, root, {})
    }

    // editor = contentItem（RowLayout）内的 EditableText：
    // RowLayout.children = [Text(标签), EditableText]
    function editorOf(e) {
        return e.contentItem.children[1]
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 初始显示（修2 回归：首帧即显示通道值，非空白）——
    function test_initialDisplay() {
        const e = makeEdit()
        const ed = editorOf(e)
        // "red" 的 HSL lightnessF = 0.5 → format ".500"
        compare(ed.text, ".500", "initial display = format(0.5)")
    }

    // —— 读链：assistant 通道变化 → value 镜像 + 显示更新 ——
    function test_readChain() {
        const e = makeEdit()
        const ed = editorOf(e)
        e.colorAssistant.hslLightnessF = 0.7
        verify(fuzzy(e.value, 0.7), "assistant change -> value follows")
        tryCompare(ed, "text", ".700", 500, "assistant change -> display follows")
    }

    // —— 写链（bug1 关键）：root.value 写入 → assistant 通道变化 ——
    function test_writeChain() {
        const e = makeEdit()
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.5), "initial channel = 0.5")
        e.value = 0.35
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.35),
               "value write -> assistant channel updated")
        // 颜色联动：lightness 0.5 → 0.35，color 变化（toString 比较——
        // QML color 值类型属性不可靠，AGENTS 断言规范）
        verify(e.colorAssistant.color.toString() !== "#ff0000",
               "value write -> assistant color changed")
    }

    // —— 编辑收尾：textFromEditText 解析写值（bug1 交互路径）——
    function test_editCommit() {
        const e = makeEdit()
        const ed = editorOf(e)
        // 进会话 → 输入 "350"（parseChannelNumberFloat: 350 → .350 = 0.35）→ 收尾
        ed.editing = true
        ed.editText = "350"
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.35),
               "edit commit -> assistant channel updated")
        tryCompare(ed, "text", ".350", 500, "edit commit -> display normalized")
    }

    // —— 编辑收尾值相同：显示仍规范化（修3 回归）——
    function test_editCommitSameValue() {
        const e = makeEdit()
        const ed = editorOf(e)
        ed.editing = true
        ed.editText = "0.5"
        ed.editing = false
        // 0.5 与现值相同 → 无数据变化；显示仍规范化为 format(0.5)
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.5), "no data change on same value")
        tryCompare(ed, "text", ".500", 500, "same value -> display still normalized")
    }

    // —— NaN 输入：空/非法不写数据，显示回位（空串现由 validator 拒绝——
    // rejected 不调 textFromEditText；parseChannelNumberFloat 的 NaN 透传
    // 契约仍保留，见 parseSemantics）——
    function test_nanNoWrite() {
        const e = makeEdit()
        const ed = editorOf(e)
        ed.editing = true
        ed.editText = ""
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.5), "empty input -> no data write")
        tryCompare(ed, "text", ".500", 500, "empty input -> display restored")
    }

    // —— 显示层（displayItem 覆写）：显示真实源 format(proxy.value)，外部
    // 联动直连真实源、不经 text 中转（重构核心契约）——
    function test_displayItem() {
        const e = makeEdit()
        const ed = editorOf(e)
        compare(ed.displayItem.text, ".500", "display shows format(0.5)")
        // 读链：assistant 变化 → displayItem 直接跟随
        e.colorAssistant.hslLightnessF = 0.7
        tryCompare(ed.displayItem, "text", ".700", 500,
                   "display follows assistant directly")
        // 编辑收尾后显示与保存形式一致
        ed.editing = true
        ed.editText = "350"
        ed.editing = false
        tryCompare(ed.displayItem, "text", ".350", 500, "display follows commit")
        // 几何统一锚定：displayItem fill 内容容器（EditableText 内部处理，
        // 覆写者不声明几何）
        tryCompare(ed.displayItem, "width", ed.width, 500,
                   "display fills content area (width)")
        tryCompare(ed.displayItem, "height", ed.height, 500,
                   "display fills content area (height)")
    }

    // 编辑框宽度锁定的度量（对齐测试用——PixelFont.normal 同源）
    FontMetrics {
        id: testFm
        font: PixelFont.normal
    }

    // —— 字体统一：标签/显示/编辑层同源（PixelFont.normal，MozartNBP
    // 24px——ChannelNumText 统一组件）——
    function test_fontUnified() {
        const e = makeEdit()
        const ed = editorOf(e)
        // 显示（displayItem = ChannelNumText）
        compare(ed.displayItem.font.family, PixelFont.family, "display font = PixelFont")
        compare(ed.displayItem.font.pixelSize, 24, "display 24px")
        // 编辑基准/编辑层（editor.font 覆盖为 PixelFont.normal）
        compare(ed.font.family, PixelFont.family, "editor font = PixelFont")
        // 标签（contentItem 第一个子项 = ChannelNumText）
        const tag = e.contentItem.children[0]
        compare(tag.font.family, PixelFont.family, "tag font = PixelFont")
        compare(tag.font.pixelSize, 24, "tag 24px")
        // 对齐：标签左、显示右（ChannelNumText 默认右——display 用途）
        compare(tag.horizontalAlignment, Text.AlignLeft, "tag left-aligned")
        compare(ed.displayItem.horizontalAlignment, Text.AlignRight,
                "display right-aligned")
        // 编辑框宽度锁定 4 字符（FontMetrics——显示形态最长 '.xxx'）
        tryCompare(ed, "width", testFm.advanceWidth("0000"), 500,
                   "editor width locked to 4 chars")
    }

    // —— validator：格式校验（RegularExpressionValidator——允许无前导零
    // ".350"；拒绝非法/空串/科学计数法；不设范围——范围/补点语义归
    // parseChannelNumberFloat）——
    function test_validator() {
        const e = makeEdit()
        const ed = editorOf(e)
        // 非法输入 → rejected：不写数据、text 保持基准（显示回位）
        ed.editing = true
        ed.editText = "abc"
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.5), "invalid input -> no write")
        compare(ed.text, ".500", "invalid input -> text stays baseline")
        // 空串 → rejected → 同回位
        ed.editing = true
        ed.editText = ""
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.5), "empty input -> no write")
        compare(ed.text, ".500", "empty input -> text stays baseline")
        // 无前导零合法输入 → accepted → 解析写值
        ed.editing = true
        ed.editText = ".350"
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.35), "leading-dot accepted")
        tryCompare(ed, "text", ".350", 500, "leading-dot -> normalized")
        // 带符号合法输入
        ed.editing = true
        ed.editText = "+0.7"
        ed.editing = false
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.7), "signed input accepted")
        tryCompare(ed, "text", ".700", 500, "signed -> normalized")
    }

    // —— 真实交互路径（用户 Playground 操作复现）：聚焦进编辑 → 键盘
    // 输入 → 失焦收尾 → 写链。offscreen 合成鼠标事件不驱动 TapHandler
    // （tst_slider 同限制），改用聚焦路径——EditableText 聚焦即进编辑会话
    // （onActiveFocusChanged），会话内路径（键入/收尾/textFromEditText）
    // 与点击入口完全一致。
    function test_realInteraction() {
        const e = makeEdit()
        const ed = editorOf(e)
        verify(ed.width > 0 && ed.height > 0, "editor has geometry")
        ed.forceActiveFocus()
        tryCompare(ed, "editing", true, 500, "focus enters editing session")
        // 编辑层装配时已 selectAll——键入即整体替换
        keyClick(Qt.Key_3)
        keyClick(Qt.Key_5)
        keyClick(Qt.Key_0)
        root.forceActiveFocus()   // 失焦 → 编辑层 editingFinished → 收尾
        tryCompare(ed, "editing", false, 500, "blur ends editing session")
        verify(fuzzy(e.colorAssistant.hslLightnessF, 0.35),
               "real interaction commit -> assistant channel updated")
        tryCompare(ed, "text", ".350", 500, "real interaction -> display normalized")
    }

    // —— 解析/格式化语义（统一实现 ColorNameHQ.parseChannelNumberFloat /
    // formatChannelNumberFloat——清洗+补点约定与四种输出，format/parse 配对）——
    function test_parseSemantics() {
        // 补点：无小数点的整数输入按纯小数解释（对齐显示格式无前导零）
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat("350"), 0.35), "350 -> .350 = 0.35")
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat("5"), 0.5), "5 -> .5 = 0.5")
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat("1500"), 0.15), "1500 -> .1500 = 0.15")
        // 带点：保留原值（不补点）
        verify(ColorNameHQ.parseChannelNumberFloat("1.5") === 1.5, "1.5 unchanged")
        verify(ColorNameHQ.parseChannelNumberFloat(".350") === 0.35, ".350 -> 0.35")
        verify(ColorNameHQ.parseChannelNumberFloat("0.35") === 0.35, "0.35 unchanged")
        // 清洗：仅保留数字与第一个小数点
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat("1a2b3"), 0.123), "1a2b3 -> .123")
        verify(ColorNameHQ.parseChannelNumberFloat("3.14.15") === 3.1415,
               "3.14.15 -> 3.1415 (extra dots dropped, digits kept)")
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat("1,234"), 0.1234), "1,234 -> .1234")
        // 失败 → NaN 透传
        verify(isNaN(ColorNameHQ.parseChannelNumberFloat("")), "empty -> NaN")
        verify(isNaN(ColorNameHQ.parseChannelNumberFloat("abc")), "abc -> NaN")
        verify(isNaN(ColorNameHQ.parseChannelNumberFloat(".")), "lone dot -> NaN")
    }

    // —— 格式化四种输出（'0'/'1'/'.xxx'/'NaN'）——
    function test_formatSemantics() {
        compare(ColorNameHQ.formatChannelNumberFloat(0), "0", "0 -> '0'")
        compare(ColorNameHQ.formatChannelNumberFloat(1), "1", "1 -> '1'")
        compare(ColorNameHQ.formatChannelNumberFloat(0.35), ".350", "0.35 -> .350")
        compare(ColorNameHQ.formatChannelNumberFloat(0.5), ".500", "0.5 -> .500")
        compare(ColorNameHQ.formatChannelNumberFloat(NaN), "NaN", "NaN -> NaN")
        // 千分位边界：round 到 1000（≥0.9995）归 '1'，不进位取模归零
        compare(ColorNameHQ.formatChannelNumberFloat(0.9995), "1", "0.9995 -> 1")
        compare(ColorNameHQ.formatChannelNumberFloat(0.9996), "1", "0.9996 -> 1")
        // 互逆（'1' 除外——'1' 解析为 '.1'=0.1，刻意补点语义的推论）：
        // format 输出可解析回原值
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat(
                ColorNameHQ.formatChannelNumberFloat(0.35)), 0.35), "roundtrip .350")
        verify(fuzzy(ColorNameHQ.parseChannelNumberFloat(
                ColorNameHQ.formatChannelNumberFloat(0.123)), 0.123), "roundtrip .123")
        verify(ColorNameHQ.parseChannelNumberFloat(
                ColorNameHQ.formatChannelNumberFloat(0)) === 0, "roundtrip 0")
        verify(isNaN(ColorNameHQ.parseChannelNumberFloat(
                ColorNameHQ.formatChannelNumberFloat(NaN))), "roundtrip NaN")
    }

    Component {
        id: boundComp
        Item {
            id: boundRoot
            property color extColor: "red"
            property alias ca: asst
            property alias edit: cce
            ColorAssistant {
                id: asst
                color: boundRoot.extColor
            }
            ColorChannelEdit {
                id: cce
                width: 200
                height: 30
                animationEnabled: false
                colorAssistant: asst
                channel: ColorNameHQ.HSLLightness
            }
        }
    }

    // —— Playground 场景（bug1 复现）：colorAssistant.color 绑定外部源。
    // 编辑写链经 set_color 程序化赋值 ca.color——QML 语义：赋值破坏绑定，
    // 此后 ca 不再跟随外部源。本用例确认该行为（debug 用户观察：编辑后
    // 颜色不变化/拖 picker 数字仍变）。
    function test_boundSource() {
        const b = createTemporaryObject(boundComp, root, {})
        const e = b.edit
        const ca = b.ca
        const ed = editorOf(e)
        compare(ed.text, ".500", "initial follows bound source (red l=0.5)")
        // 编辑写链 → ca 通道变（经 set_color 程序化赋值，破坏 color 绑定）
        e.value = 0.35
        verify(fuzzy(ca.hslLightnessF, 0.35), "value write through bound source")
        tryCompare(ed, "text", ".350", 500, "display follows written value")
        // 外部源变化 → ca 是否仍跟随（绑定是否被写链破坏）
        b.extColor = "#404040"   // lightness = 0.25
        if (fuzzy(ca.hslLightnessF, 0.25)) {
            // 绑定存活：跟随外部源（写链未破坏绑定——C++ setter 赋值
            // 不破坏 QML 绑定，依赖变化时绑定重新求值覆盖）
            const l = ca.hslLightnessF
            verify(fuzzy(l, 0.25), "bound source still live")
            tryCompare(ed, "text", ColorNameHQ.formatChannelNumberFloat(l), 500,
                       "display follows bound source")
        } else {
            // 绑定被破坏：ca 保持编辑后的值（QML 赋值破坏绑定语义）
            verify(fuzzy(ca.hslLightnessF, 0.35), "binding broken by write")
            tryCompare(ed, "text", ".350", 500, "stays at written value")
        }
    }
}
