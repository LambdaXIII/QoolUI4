import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool

// Qool.Controls.TextField：Qool 系列文本组件主角——双层强化版（展示层 +
// 编辑层 + 编辑会话）。系列可编辑控件（ComboBox/SpinBox，未来迁移）的
// 编辑域统一消费本类型。
//
// 双层定位：展示与编辑是两个独立文本对象（双层结构本质，v3 传统覆盖
// 模式——v3 无单层常驻输入框）。
// - 平时：displayItem（Item 实例，默认 Text）常驻展示——text 经插拔函数
//   displayTextFromText 派生 displayText 驱动。
// - 点击/聚焦进编辑会话后：Loader 延迟加载 BasicTextField 覆盖编辑（编辑
//   态状态隔离：会话数据只在编辑层）；会话结束即卸载（大量实例资源节约）。
//
// 文本模型（Qool 扩展）：
// - text：主内容（可写）。编辑结束经 textFromEditText 提交更新。
// - displayText：只读派生（=== displayTextFromText(text)）。
// - editText：编辑会话实时通道。非编辑期跟随 text（onTextChanged 手动同步
//   ——不用属性绑定，避免绑定被编辑期赋值破坏的隐式语义）；编辑中与编辑层
//   双向同步（onTextEdited 回写 / onEditTextChanged 下发，同值守卫无循环）；
//   非编辑写入无预设语义（不保证——不做"程序化 text 更新 vs 编辑提交"的
//   识别）。
// 插拔哲学：displayTextFromText / textFromEditText / displayItem 默认实现
// 全部提供（恒等函数 / Text 组件），宿主经派生类覆盖任一（QML 函数遮蔽
// 语言机制，同 SpinBox 三钩子）不影响链路。
//
// 编辑会话（editing 可写——设 true/false 进出；官方无此接口，Qool 扩展）：
// - **editing 是信号与行为的衔接点**：进入/结束意图（点击/聚焦/Enter/失焦/
//   程序化）只负责置 editing（唯一状态源），行为统一从 onEditingChanged
//   启动——true → Loader 绑定装配；false → 数据回流（可接受 → text =
//   textFromEditText；不可接受 → 回退）+ editingFinished——程序化与交互路径
//   行为一致。
// - 统一收尾（无取消、无 Esc 区分）：Esc = 普通失焦（编辑层
//   Keys.onEscapePressed → focus=false），落入同一收尾路径。
// - Enter 非法：编辑保持 + rejected() 转发（判定下沉 BasicTextField——宣告型
//   逻辑放基底，本层一行转发）。
// - 回流数据在结束意图点提取（field 必然存在），不依赖 Loader 卸载时序。
//
// 契约差异（与 Qt 官方 TextField 对照）：
// - 官方 TextField 单层常驻输入（displayText 与编辑同一文本对象）；本类型
//   双层分离、displayText 只读派生、编辑会话状态机。
// - editing / editingStarted() / editingFinished() / rejected() 为 Qool 扩展
//   （官方无编辑会话开关与对应信号）。
// - 裸控件：无壳层视觉（背景盒/标题/壳层 covers 由宿主包装 QoolControl
//   提供）——与 SpinBox 同定位。
//
// 待验证（调试时实测确认，2026-08-10）：
// - FocusScope 焦点回退：编辑层卸载（Loader 销毁）后焦点应自动回退到域内
//   本控件（Qt 惯例"控件保留焦点"）；若实测不回退，需显式 forceActiveFocus
//   回本体（卸载后无对象可释放焦点，焦点归位机制待实测确认）。
// - Loader active 绑定求值时机：onLoaded 装配依赖 item 已创建并入树（规避
//   "信号处理器内绑定延迟求值"——置 editing 当刻读 editLoader.item 不可靠）。

T.Control {
    id: root

    /* 文本模型：主内容（可写）。编辑结束经 textFromEditText 提交更新；
       平时经 displayTextFromText 派生展示。 */
    property string text

    /* 展示文本：只读派生（插拔点 displayTextFromText）。 */
    readonly property string displayText: displayTextFromText(root.text)

    /* 编辑会话实时通道：非编辑期跟随 text；编辑中与编辑层双向同步；非编辑
       写入无预设语义（不保证）。 */
    property string editText: root.text

    /* 编辑层校验：var 属性，声明式绑定转发（Loader 实例化时绑定自动
       建立——无需显式 Binding 对象）。 */
    property var validator

    /* 编辑会话开关（Qool 扩展）：true = 会话进行中（编辑层在场）。宿主
       设 true/false 进出会话；点击/聚焦/收尾路径亦驱动本属性。 */
    property bool editing: false

    /* 编辑开关（TextField 惯例命名，不提供 editable——反相冗余）：true =
       只读。不启动会话（点击/聚焦空转）；编辑层亦只读（显式会话可聚焦
       选中，不可编辑）。 */
    property bool readOnly: false

    /* 文本色：display 与编辑层共用（T.Control 无 color，Qool 扩展）。 */
    property color color: Style.text

    // display 与编辑层共用（编辑层经转发继承——切换无视觉跳动）
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignVCenter

    /* 展示组件（内容主体——Item 实例属性，几何自管；默认 Text 写
       anchors.fill: parent）。编辑时经 Binding 隐藏（不卸载——会话结束
       恢复，无重建开销）。 */
    property Item displayItem: Text {
        text: root.displayText
        font: root.font
        color: root.color
        enabled: root.enabled
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        anchors.fill: parent
        BasicTextBehavior on text {}
    }

    /* 插拔函数（默认恒等）：text → 展示文本派生。宿主派生类覆盖同名
       函数即生效（QML 函数遮蔽语言机制，同 SpinBox 三钩子）——displayText
       绑定调用动态解析，text 变化时走覆盖实现。 */
    function displayTextFromText(text) {
        return text;
    }

    /* 插拔函数（默认恒等）：编辑层文本 → text 提交还原。 */
    function textFromEditText(text) {
        return text;
    }

    /* Qool 扩展会话信号：进入编辑会话（编辑层已就绪，宿主可读 editText）/
       结束编辑会话（text 已提交或回退完毕，宿主读 text）/ Enter 非法被拒
       （编辑保持，宿主提示）。 */
    signal editingStarted
    signal editingFinished
    signal rejected

    // 点击聚焦/进编辑由 contentItem 的 TapHandler 实现（无需 activeFocusOnTap——
    // 该属性不存在）；Tab 聚焦需显式开启——T.Control 基座默认 false
    // （AbstractButton/文本域的默认 true 不适用于本基座）
    activeFocusOnTab: true
    font.pixelSize: Style.controlTextSize

    // 衔接点：editing 变化统一启动行为——true 无需动作（Loader 绑定激活 →
    // onLoaded 装配）；false → 统一收尾（数据回流 + editingFinished，隐藏/
    // 卸载自动）
    onEditingChanged: if (!root.editing)
                          pCtrl.finish_edit()

    // 聚焦即编辑（与点击一致）：Tab/点击聚焦 → 置 editing（进入意图 = 置
    // editing，行为从 onEditingChanged 启动）。readOnly 过滤；编辑层
    // forceActiveFocus 在域内（T.Control = QQuickFocusScope），不改变
    // root.activeFocus → 本处理器不重入。
    onActiveFocusChanged: if (activeFocus && !root.editing && !root.readOnly)
                              root.editing = true

    // 非编辑期 text 更新 → editText 跟随（"默认 = text"语义；编辑中会话通道
    // 接管，程序化 text 更新不干扰编辑层）
    onTextChanged: if (!root.editing)
        root.editText = root.text

    // 编辑期程序化 editText 写入 → 下发编辑层（同值赋值不触发 change，与
    // onTextEdited 回写间无循环）。非编辑期 Loader 未加载，空转。
    onEditTextChanged: {
        let field = editLoader.item;
        if (field)
            field.text = root.editText;
    }

    contentItem: Item {
        id: contentContainer

        // 默认尺寸随展示内容（displayItem 几何自管；宿主自定义时以其隐式
        // 尺寸为准——implicitWidth 为内容宽，不受 anchors 拉伸影响）
        implicitWidth: root.displayItem ? root.displayItem.implicitWidth : 0
        implicitHeight: root.displayItem ? root.displayItem.implicitHeight : 0

        /* 编辑层：Loader 延迟加载 + 结束卸载（编辑会话状态隔离 + 大量实例
           资源节约）。装配（填入 editText、selectAll、抢焦点）在 onLoaded——
           此时 item 已创建并入树，forceActiveFocus 可靠（规避信号处理器内
           绑定延迟求值：置 editing 当刻 item 可能未就绪）。 */
        Loader {
            id: editLoader
            anchors.fill: parent
            active: root.editing
            onLoaded: pCtrl.setup_edit()
            sourceComponent: BasicTextField {

                font: root.font
                color: root.color
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment
                validator: root.validator
                readOnly: root.readOnly
                enabled: root.enabled
                selectByMouse: true // 编辑态固定允许鼠标选择（selectAll 后键入覆盖）
                padding: 0 // 与 display 对齐（默认 Text 无 padding）——双层切换无位移

                // 编辑 → editText 回写（本类型非模板文本域，editText 是唯一
                // 编辑通道——无 Loader 识别缺口问题）
                onTextEdited: root.editText = text

                // Enter 合法（accepted 保证可接受）→ 结束意图（提取 + 置 false）
                onAccepted: pCtrl.submit_edit()

                // 失焦（含 Esc/窗口失活）→ 结束意图（提取状态后置 false）。
                // 不用 onEditingFinished：实例 handler 赋值会覆盖 BasicTextField
                // 内部定义的 rejected 判定（QML 实例属性覆盖组件定义 handler，
                // 同一信号仅一个）——onEditingFinished 留给基座内部判定，失焦
                // 经 onActiveFocusChanged（基座未用，不冲突）
                onActiveFocusChanged: if (!activeFocus && root.editing)
                                          pCtrl.leave_edit()

                // Enter 非法（判定下沉 BasicTextField——宣告型逻辑在基底，
                // 本层一行转发），编辑保持
                onRejected: root.rejected()

                // Esc = 普通失焦（= 失焦路径，落入统一收尾）。不下沉
                // BasicTextField：其定位是主题化默认 TextField，不掺行为决策；
                // Esc 收尾是行为型，属本层对"会话结束方式"的控制。
                Keys.onEscapePressed: focus = false
            }
        }

        // 点击进编辑（display 区域）：readOnly/会话中禁用（编辑层自理点击，
        // 同时天然让位 IME——官方 inputMethodComposing 语义要求 composing
        // 期间点击交输入法编辑预编辑文本）。进入意图 = 置 editing。
        TapHandler {
            enabled: !root.readOnly && !root.editing
            onTapped: root.editing = true
        }
    }//contentItem

    // displayItem 置入内容层：宿主内联声明实例默认 parent = 控件根，需重
    // parent；几何不动（自管）。target 为绑定——宿主替换 displayItem 时
    // 新实例同样置入。
    Binding {
        target: root.displayItem
        property: "parent"
        value: contentContainer
    }

    // 编辑时隐藏展示层（不卸载——会话结束恢复，无重建开销）
    Binding {
        target: root.displayItem
        property: "visible"
        value: !root.editing
    }

    /* 逻辑对象：编辑会话状态机。editing 是信号与行为的衔接点——进入/结束
       意图（点击/聚焦/Enter/失焦/程序化）只负责置 editing（唯一状态源），
       行为统一从 onEditingChanged 启动（true → Loader 绑定装配；false → 数据
       回流 + editingFinished），程序化与交互路径行为一致。 */
    QtObject {
        id: pCtrl

        // 结束意图点提取的编辑层状态：Loader 卸载（active 绑定求值）后 field
        // 可能已不可读，而回流需要它——在意图点（editing 仍 true，field 必然
        // 存在）提取，回流不依赖卸载时序
        property bool lastAcceptable: false

        // 装配（Loader.onLoaded——item 已入树）：填 editText → selectAll
        // （键入即整体替换）→ 抢焦点（域内，不破坏外部焦点链）。
        function setup_edit() {
            let field = editLoader.item
            if (!field)
                return
            field.text = root.editText
            field.selectAll()
            field.forceActiveFocus()
            root.editingStarted()
        }

        // 结束意图（Enter 合法）：accepted 信号保证可接受，直接置 false
        function submit_edit() {
            pCtrl.lastAcceptable = true
            root.editing = false
        }

        // 结束意图（失焦，含 Esc/窗口失活）：提取编辑层状态后置 false
        function leave_edit() {
            let field = editLoader.item
            pCtrl.lastAcceptable = field ? field.acceptableInput : false
            root.editing = false
        }

        // 统一收尾（onEditingChanged(false)——所有结束路径汇聚于此）：
        // 数据回流（可接受 → text = textFromEditText(编辑文本)；不可接受 →
        // 回退 text 不变）→ editingFinished 信号。displayItem 恢复显示
        // （visible Binding）与编辑层卸载（Loader active 绑定）自动发生。
        function finish_edit() {
            let field = editLoader.item
            let accepted = field ? field.acceptableInput : pCtrl.lastAcceptable
            let value = field ? field.text : root.editText
            if (accepted)
                root.text = root.textFromEditText(value)
            root.editingFinished()
        }
    }//pCtrl

    background: Item {
        //透明背景，仅提供尺寸
        implicitHeight: 10
        implicitWidth: 10
    }
}
