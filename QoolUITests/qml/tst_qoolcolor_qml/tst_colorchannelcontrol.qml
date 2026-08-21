import QtQuick
import QtTest
import Qool
import Qool.Color

// ColorChannelControl 测试（Qool.Color/ColorChannelControl.qml——单通道
// 「数值编辑 + 拖动调值」组合件：Control 基座竖直堆叠 ColorChannelEdit +
// ColorChannelSlider，集束共有属性外壳统一声明转发）。
//
// 被测契约（外部行为与公开契约——docs/reference/Qool.Color/ColorChannelControl.md
// 为准绳，逐条对应）：
// - 布局：编辑在上、滑块在下、两行等宽（fillWidth）、零间距
// - 属性集束转发：外壳 channel/colorAssistant/animationEnabled → 两子组件跟随；
//   colorAssistant 单一共享实例（集束不变量——两子组件链向同一实例）
// - value 双向链：外壳自持 PropertyProxy ↔ assistant（独立第三投影）——
//   写外壳 value → assistant 通道变化；改 assistant 通道 → 外壳 value 回读；
//   onCompleted 播种（assistant 预设色 → 外壳 value = 通道值）
// - readOnly 传递：外壳 readOnly → 编辑子组件 → 编辑层（不启动编辑会话）；
//   滑块/链不受只读影响
// - 子组件汇聚：滑块 value 经同一 assistant 与外壳 value 收敛
//
// 隔离：每个测试函数独立实例；动画统一关闭（animationEnabled: false）。
// 真实鼠标交互不在自动化范围（offscreen 不注入合成事件，与
// tst_colorchanneledit/tst_colorchannelslider 同策略）。
//
// 断言第三参一律 ASCII 英文（QoolUITests/AGENTS 断言规范——非 ASCII 第三
// 参有加载期静默失败风险，勿写中文）。

TestCase {
    id: root

    name: "ColorChannelControl"
    width: 400
    height: 300

    // 默认组件：assistant 颜色经 __assistantColor 参数注入（JS 属性映射
    // 无法内联 QML 对象字面量——createTemporaryObject 的属性在组件完成前
    // 应用，播种读到的就是注入色，同 tst_colorchannelslider 惯例）
    Component {
        id: controlComp
        ColorChannelControl {
            id: control
            width: 300
            animationEnabled: false
            property color __assistantColor: "#ff0000"
            colorAssistant: ColorAssistant {
                color: control.__assistantColor
            }
            channel: ColorNameHQ.HSLLightness
        }
    }

    function makeControl(extra) {
        const props = extra === undefined ? {} : extra
        return createTemporaryObject(controlComp, root, props)
    }

    // contentItem（ColumnLayout）子项定位：children[0] = ColorChannelEdit、
    // children[1] = ColorChannelSlider（声明序）。
    function editOf(c) {
        return c.contentItem.children[0]
    }

    function sliderOf(c) {
        return c.contentItem.children[1]
    }

    // 编辑子组件 contentItem（RowLayout）内 EditableText（同
    // tst_colorchanneledit.editorOf 惯例）
    function editorOf(e) {
        return e.contentItem.children[1]
    }

    function fuzzy(x, y) {
        return Math.abs(x - y) < 0.001
    }

    // —— 布局：编辑在上、滑块在下、两行等宽、零间距（自然尺寸——隐式高
    // = 编辑高 + 滑块高；显式加高时多余空间由 ColumnLayout 分配，非本
    // 组件契约）——
    function test_layout() {
        const c = makeControl({})
        const edit = editOf(c)
        const slider = sliderOf(c)
        verify(edit.width > 0 && edit.height > 0, "children have geometry")
        verify(slider.width > 0 && slider.height > 0, "slider has geometry")
        // 等宽：两行 = 外壳可用宽（ColumnLayout fillWidth）
        tryCompare(edit, "width", c.availableWidth, 500, "edit width fills shell")
        tryCompare(slider, "width", c.availableWidth, 500, "slider width fills shell")
        compare(edit.width, slider.width, "equal width")
        // 竖直堆叠：edit 在上（y=0）、slider 紧随其下、零间距
        compare(edit.y, 0, "edit on top")
        verify(Math.abs(slider.y - (edit.y + edit.height)) < 0.001,
               "slider directly below edit (zero spacing)")
        // 外壳隐式高 = 编辑高 + 滑块高（内容贴合）
        verify(Math.abs(c.height - (edit.height + slider.height)) < 0.001,
               "shell implicit height = edit + slider")
    }

    // —— 属性集束转发：channel/colorAssistant/animationEnabled ——
    function test_bundling() {
        const c = makeControl({})
        const edit = editOf(c)
        const slider = sliderOf(c)
        // channel 转发：外壳设 → 两子组件跟随
        c.channel = ColorNameHQ.Red
        compare(edit.channel, ColorNameHQ.Red, "edit channel follows shell")
        compare(slider.channel, ColorNameHQ.Red, "slider channel follows shell")
        // colorAssistant 单一共享实例（集束不变量——编辑与拖动同链）
        verify(edit.colorAssistant === c.colorAssistant,
               "edit shares shell assistant instance")
        verify(slider.colorAssistant === c.colorAssistant,
               "slider shares shell assistant instance")
        verify(slider.colorAssistant === edit.colorAssistant,
               "single shared assistant instance")
        // animationEnabled 转发（显式 root 引用——不依赖 parent 链）
        c.animationEnabled = false
        compare(edit.animationEnabled, false, "edit animation follows shell")
        compare(slider.animationEnabled, false, "slider animation follows shell")
    }

    // —— value 双向链 + 播种（外壳自持第三投影，经同一 assistant 汇聚）——
    function test_valueChain() {
        const c = makeControl({})
        const slider = sliderOf(c)
        // onCompleted 播种：red → HSL lightness 0.5
        verify(fuzzy(c.value, 0.5), "seed: red lightness -> 0.5")
        // 写方向：外壳 value → assistant 通道
        c.value = 0.35
        verify(fuzzy(c.colorAssistant.hslLightnessF, 0.35),
               "shell value write -> assistant channel")
        // 读方向：assistant 通道 → 外壳 value 回读
        c.colorAssistant.hslLightnessF = 0.7
        verify(fuzzy(c.value, 0.7), "assistant change -> shell value follows")
        // 子组件汇聚：滑块 value 经同一 assistant 收敛（读方向同源）
        verify(fuzzy(slider.value, 0.7), "slider converges via shared assistant")
        // 滑块侧写入（拖动模拟——程序化 value）→ 外壳 value 跟随
        slider.value = 0.2
        verify(fuzzy(c.colorAssistant.hslLightnessF, 0.2),
               "slider write -> assistant channel")
        verify(fuzzy(c.value, 0.2), "shell value follows slider write")
    }

    // —— readOnly 传递：外壳 → 编辑层；滑块/链不受只读影响 ——
    function test_readOnly() {
        const c = makeControl({})
        const edit = editOf(c)
        const ed = editorOf(edit)
        compare(ed.readOnly, false, "default editable")
        // 转发：外壳 readOnly → 编辑层
        c.readOnly = true
        compare(ed.readOnly, true, "shell readOnly -> editor readOnly")
        // 只读不进编辑会话：聚焦空转（EditableText readOnly 契约）
        ed.forceActiveFocus()
        tryCompare(ed, "editing", false, 300, "readOnly focus does not enter session")
        // 滑块/链不受只读影响：外壳 value 仍可写、读方向仍活
        c.value = 0.6
        verify(fuzzy(c.colorAssistant.hslLightnessF, 0.6),
               "shell value write works under readOnly")
        c.colorAssistant.hslLightnessF = 0.3
        verify(fuzzy(c.value, 0.3), "chain read-back live under readOnly")
        // 释放只读 → 恢复可编辑
        c.readOnly = false
        compare(ed.readOnly, false, "readOnly released")
    }
}
