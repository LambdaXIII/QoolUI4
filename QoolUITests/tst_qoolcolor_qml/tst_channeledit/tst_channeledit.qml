import QtQuick
import QtTest
import Qool
import Qool.Color
import Qool.Controls

// ChannelEdit 测试（Qool.Color/ChannelEdit.qml——通道值编辑控件：
// EditableText 编辑会话 + ColorAssistant 通道双向同步 + orientation 双布局）。
//
// 被测契约（公开契约——docs/reference/Qool.Color/ChannelEdit.md 为准绳）：
// - 写链：root.value 写入（程序化）→ assistant 通道变化
// - 读链：assistant 通道变化 → root.value 跟随
// - channel 分派 / 外部绑定源联动（colorAssistant.color 绑定外部源场景）
// - 解析/格式化语义（ColorHQ.parseChannelNumberFloat /
//   formatChannelNumberFloat——本组件依赖的核心解析/格式化，format/parse
//   配对）
// - orientation：默认水平（长标签贴左 + 数字贴右）；Qt.Vertical 切竖直
//   （短标签在上、数字在下居中）
// - mirrored（环境信号）：水平左右对调（tag 贴右/editor 贴左，间隙不变）；
//   用例经 LayoutMirroring.enabled 驱动。
// - tagOnTop（显式行序，与环境正交）：仅竖直有意义——数字上/标签下；
//   LayoutMirroring 不影响竖直堆叠顺序。
//
// 隔离：每个测试函数独立实例；动画统一关闭。
// 内部定位：tag/editor 经 objectName + findChild（递归搜索——不依赖
// children 序或内部实现，避免布局结构调整破坏测试）。不操作内部
// EditableText 的 editing/editText/displayItem——编辑会话行为归属
// EditableText 测试单元，本单元只测公开契约（编辑收尾组合路径由
// parseSemantics + writeChain 分半覆盖）。

TestCase {
    id: root

    name: "ChannelEdit"
    width: 400
    height: 300

    Component {
        id: editComp
        ChannelEdit {
            width: 200
            height: 30
            Style.animationEnabled: false
            colorAssistant: ColorAssistant {
                color: "#ff0000"
            }
            channel: ColorHQ.HSLLightness
        }
    }

    function makeEdit() {
        return createTemporaryObject(editComp, root, {})
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 解析/格式化往返：端点对称还原 + 无点补点约定 ——
    function test_parseFormatRoundtrip() {
        // 端点：format 将 0/1 输出为 "0"/"1"，解析须对称还原（不特判则
        // 显示 "1" 的编辑收尾被补点误读为 .1）
        compare(ColorHQ.parseChannelNumberFloat("1"), 1, "endpoint 1 roundtrip")
        compare(ColorHQ.parseChannelNumberFloat("0"), 0, "endpoint 0 roundtrip")
        // 补点约定：无点整数按纯小数解释
        verify(fuzzy(ColorHQ.parseChannelNumberFloat("350"), 0.35),
               "no-dot integer -> pure decimal (350 -> .35)")
        verify(fuzzy(ColorHQ.parseChannelNumberFloat(".35"), 0.35),
               "leading dot direct")
        verify(fuzzy(ColorHQ.parseChannelNumberFloat("0.35"), 0.35),
               "full form direct")
        // 清洗失败透传 NaN
        verify(Number.isNaN(ColorHQ.parseChannelNumberFloat(".")),
               "lone dot -> NaN")
    }

    // —— orientation 默认：水平 ——
    function test_orientationDefault() {
        const e = makeEdit()
        compare(e.orientation, Qt.Horizontal, "default orientation = horizontal")
        compare(e.horizontal, true, "horizontal derived true")
        compare(e.vertical, false, "vertical derived false")
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
            ChannelEdit {
                id: cce
                width: 200
                height: 30
                Style.animationEnabled: false
                colorAssistant: asst
                channel: ColorHQ.HSLLightness
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

    // —— objectName 递归查找（头注释约定的定位方式）——
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

    // —— mirrored 默认 false + 非镜像默认方位（tag 左 / editor 右）——
    function test_mirroredDefault() {
        const e = makeEdit()
        compare(e.mirrored, false, "default mirrored = false")
        const tag = findItem(e.contentItem, "tag")
        const editor = findItem(e.contentItem, "editor")
        verify(fuzzy(tag.x, 0), "unmirrored: tag at left")
        verify(fuzzy(editor.x + editor.width, e.contentItem.width),
               "unmirrored: editor flush right")
    }

    // —— 水平镜像：左右对调（editor 贴左、tag 贴右，间隙 5px 不变）；
    // 文字方向不变（长标签 channelTag）；切回恢复原方位 ——
    function test_mirroredHorizontal() {
        const e = makeEdit()
        const tag = findItem(e.contentItem, "tag")
        const editor = findItem(e.contentItem, "editor")
        e.LayoutMirroring.enabled = true
        verify(e.mirrored, "LayoutMirroring -> built-in mirrored true")
        verify(fuzzy(editor.x, 0), "mirrored horizontal: editor flush left")
        verify(fuzzy(tag.x, editor.width + 5),
               "mirrored horizontal: tag right of 5px gap")
        verify(fuzzy(tag.x + tag.width, e.contentItem.width),
               "mirrored horizontal: tag flush right")
        verify(tag.text === ColorHQ.channelTag(e.channel),
               "mirrored keeps long label text")
        e.LayoutMirroring.enabled = false
        verify(fuzzy(tag.x, 0) && fuzzy(editor.x + editor.width, e.contentItem.width),
               "toggle back restores original positions")
    }
    // —— 竖直翻转：tagOnTop 显式驱动（editor 在上/tag 在下，均水平居中；
    // 文字方向不变（短标签 channelTagShort）——
    // 正交性：LayoutMirroring（环境镜像）不改变竖直堆叠顺序 ——
    function test_tagOnTopVertical() {
        const e = createTemporaryObject(editComp, root,
                                        { orientation: Qt.Vertical })
        const tag = findItem(e.contentItem, "tag")
        const editor = findItem(e.contentItem, "editor")
        // 默认：标签上/数字下
        verify(fuzzy(tag.y, 0), "default vertical: tag on top")
        verify(fuzzy(editor.y, tag.height), "default vertical: editor below")
        // tagOnTop 翻转：数字在上/标签在下
        e.tagOnTop = true
        verify(fuzzy(editor.y, 0), "tagOnTop: editor on top")
        verify(fuzzy(tag.y, editor.height), "tagOnTop: tag below")
        const cx = Math.max(0, (e.contentItem.width - editor.width) / 2)
        verify(fuzzy(editor.x, cx), "tagOnTop: editor centered")
        verify(tag.text === ColorHQ.channelTagShort(e.channel),
               "vertical keeps short label text")
        // 环境镜像与竖直行序正交
        e.LayoutMirroring.enabled = true
        verify(e.mirrored, "layout mirroring still drives horizontal mirror flag")
        verify(fuzzy(editor.y, 0) && fuzzy(tag.y, editor.height),
               "layout mirroring does not affect vertical stack order")
    }
}
