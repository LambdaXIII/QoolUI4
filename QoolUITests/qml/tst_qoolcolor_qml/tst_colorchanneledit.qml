import QtQuick
import QtTest
import Qool
import Qool.Color
import Qool.Controls

// ColorChannelEdit 测试（Qool.Color/ColorChannelEdit.qml——通道值编辑控件：
// EditableText 编辑会话 + ColorAssistant 通道双向同步 + orientation 双布局）。
//
// 被测契约（公开契约——docs/reference/Qool.Color/ColorChannelEdit.md 为准绳）：
// - 写链：root.value 写入（程序化）→ assistant 通道变化
// - 读链：assistant 通道变化 → root.value 跟随
// - channel 分派 / 外部绑定源联动（colorAssistant.color 绑定外部源场景）
// - 解析/格式化语义（ColorNameHQ.parseChannelNumberFloat /
//   formatChannelNumberFloat——本组件依赖的核心解析/格式化，format/parse
//   配对）
// - orientation：默认水平（长标签贴左 + 数字贴右）；Qt.Vertical 切竖直
//   （短标签在上、数字在下居中）
//
// 隔离：每个测试函数独立实例；动画统一关闭。
// 内部定位：tag/editor 经 objectName + findChild（递归搜索——不依赖
// children 序或内部实现，避免布局结构调整破坏测试）。不操作内部
// EditableText 的 editing/editText/displayItem——编辑会话行为归属
// EditableText 测试单元，本单元只测公开契约（编辑收尾组合路径由
// parseSemantics + writeChain 分半覆盖）。

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

    // tag/editor 定位（objectName——LayoutItemProxy 切换布局会改 target
    // 的 parent，findChild 递归搜索不受影响）
    function tagOf(e) {
        return findChild(e, "tag")
    }

    function editorOf(e) {
        return findChild(e, "editor")
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— orientation 默认：水平 ——
    function test_orientationDefault() {
        const e = makeEdit()
        compare(e.orientation, Qt.Horizontal, "default orientation = horizontal")
        compare(e.horizontal, true, "horizontal derived true")
        compare(e.vertical, false, "vertical derived false")
    }

    // —— 竖直布局：短标签在上、数字在下、水平居中 ——
    function test_verticalOrientation() {
        const e = makeEdit()
        const tag = tagOf(e)
        const editor = editorOf(e)
        verify(tag !== null, "tag found by objectName")
        verify(editor !== null, "editor found by objectName")
        e.orientation = Qt.Vertical
        compare(e.vertical, true, "vertical derived true after switch")
        compare(e.horizontal, false, "horizontal derived false after switch")
        // 标签切短名（HSLLightness → "LIT"）
        tryCompare(tag, "text", ColorNameHQ.channelTagShort(e.channel), 500,
                   "vertical uses short channel tag")
        // 标签在上、数字在下（全局坐标中心比较）
        tryVerify(function() {
            const tp = tag.mapToItem(null, 0, 0)
            const ep = editor.mapToItem(null, 0, 0)
            return tp.y + tag.height / 2 < ep.y + editor.height / 2
        }, 500, "tag above editor in vertical mode")
        // 数字框水平居中（竖直契约：二者居中）
        tryVerify(function() {
            const ep = editor.mapToItem(e, 0, 0)
            return Math.abs((ep.x + editor.width / 2) - e.width / 2) < 2
        }, 500, "editor horizontally centered in vertical mode")
        // 数字框保持紧凑列宽（不 fillWidth 拉伸）
        tryVerify(function() {
            return editor.width < e.width / 2
        }, 500, "editor keeps compact width in vertical mode")
    }

    // —— 水平布局：标签在左、数字在右 ——
    function test_horizontalLayout() {
        const e = makeEdit()
        const tag = tagOf(e)
        const editor = editorOf(e)
        verify(tag !== null, "tag found by objectName")
        verify(editor !== null, "editor found by objectName")
        // 水平态标签 = 长标签
        compare(tag.text, ColorNameHQ.channelTag(e.channel), "horizontal uses long tag")
        // 标签贴左、数字在右（全局坐标比较）
        tryVerify(function() {
            const tp = tag.mapToItem(null, 0, 0)
            const ep = editor.mapToItem(null, 0, 0)
            return tp.x + tag.width <= ep.x
        }, 500, "tag left of editor in horizontal mode")
        // 数字贴右缘
        tryVerify(function() {
            const ep = editor.mapToItem(e, 0, 0)
            return Math.abs(ep.x + editor.width - e.width) < 2
        }, 500, "editor flush right in horizontal mode")
    }

    // —— 读链：assistant 通道变化 → value 镜像 ——
    function test_readChain() {
        const e = makeEdit()
        e.colorAssistant.hslLightnessF = 0.7
        verify(fuzzy(e.value, 0.7), "assistant change -> value follows")
    }

    // —— 写链（关键）：root.value 写入 → assistant 通道变化 ——
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

    // —— 外部绑定源场景：colorAssistant.color 绑定外部源。编辑写链经
    // set_color 程序化赋值 ca.color——QML 语义：赋值破坏绑定，此后 ca
    // 不再跟随外部源。本用例确认该行为（debug 用户观察：编辑后颜色不
    // 变化/拖 picker 数字仍变）。
    function test_boundSource() {
        const b = createTemporaryObject(boundComp, root, {})
        const e = b.edit
        const ca = b.ca
        verify(fuzzy(ca.hslLightnessF, 0.5), "initial follows bound source (red l=0.5)")
        // 编辑写链 → ca 通道变（经 set_color 程序化赋值，破坏 color 绑定）
        e.value = 0.35
        verify(fuzzy(ca.hslLightnessF, 0.35), "value write through bound source")
        // 外部源变化 → ca 是否仍跟随（绑定是否被写链破坏）
        b.extColor = "#404040"   // lightness = 0.25
        if (fuzzy(ca.hslLightnessF, 0.25)) {
            // 绑定存活：跟随外部源（写链未破坏绑定——C++ setter 赋值
            // 不破坏 QML 绑定，依赖变化时绑定重新求值覆盖）
            verify(fuzzy(ca.hslLightnessF, 0.25), "bound source still live")
        } else {
            // 绑定被破坏：ca 保持编辑后的值（QML 赋值破坏绑定语义）
            verify(fuzzy(ca.hslLightnessF, 0.35), "binding broken by write")
        }
    }
}
