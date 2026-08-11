import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool

// Qool.Controls.EditableText：Qool 系列文本组件主角——双层强化版（展示层 +
// 编辑层 + 编辑模型）。系列可编辑控件（ComboBox/SpinBox，未来迁移）的
// 编辑域统一消费本类型。
//
// 双层定位：展示与编辑是两个独立文本对象（双层结构本质，v3 传统覆盖
// 模式——v3 无单层常驻输入框）。
// - 平时：displayItem（Item 实例，默认 Text）常驻展示——text 经插拔函数
//   displayTextFromText 派生 displayText 驱动。
// - 点击/聚焦进编辑会话后：Loader 延迟加载 BasicTextField 呈现编辑（会话
//   结束即卸载——大量实例资源节约）；会话数据不驻编辑层（见编辑模型）。
//
// 编辑模型（Qool 扩展）——judge（隐藏 TextInput，常驻）：
// - judge 是编辑会话的模型层：持有会话文本（judge.text）+ validator
//   （root.validator alias 直通——单点事实源）+ acceptableInput（随文本
//   实时校验——任何时点可读，判定不依赖编辑层生命周期）。
// - 呈现层（Loader 内 BasicTextField）无状态：显示 judge.text、输入回写
//   judge（onTextEdited——用户输入即回写；程序化赋值不发 textEdited——
//   初始无污染）。非编辑期 judge.text 跟随 root.text 经 Connections 手动
//   同步 + 收尾显式恢复（不用 Binding 组件覆盖/恢复——其恢复时序
//   （delayed + restoreMode）在编辑层卸载时不可靠——会话文本残留）。
// - 编辑层**不挂 validator**：其 accepted/editingFinished 因此无条件发——
//   结束尝试（Enter/失焦/Esc 全覆盖）100% 可识别，判定全部收拢本类型
//   层（Qt validator 的 accepted 条件机制不介入——见下）。
// - accepted/rejected 为 root **独立信号**（判定结果——非编辑层信号转发）：
//   结束尝试 → 判定 judge.acceptableInput → 接受（text = textFromEditText
//   + accepted）/ 拒绝（不写 + rejected）→ 结束编辑 → editingFinished。
//   输入内容与当前 text 一致 = 无处理——accepted/rejected 均不触发。
//
// 文本模型（Qool 扩展）：
// - text：主内容（可写）。编辑结束经 textFromEditText 提交更新。
// - displayText：只读派生（=== displayTextFromText(text)）。
// - editText：编辑会话实时通道（alias judge.text——单点）。非编辑期跟随
//   text（judge 手动同步）；编辑期与编辑层双向同步（编辑层回写 judge /
//   judge 下发编辑层——同值守卫无循环）。非编辑写入无预设语义（不保证）。
// 插拔哲学：displayTextFromText / textFromEditText / displayItem 默认实现
// 全部提供（恒等函数 / Text 组件），宿主经派生类覆盖任一（QML 函数遮蔽
// 语言机制，同 SpinBox 三钩子）不影响链路。
// 转换函数语义：displayTextFromText（保存 → 呈现——展示过程）与
// textFromEditText（编辑文本 → 保存——收尾过程）**相互独立**——各自服务
// 各自过程，不假设互为逆；实现为互逆运算是可行用法（编辑呈现形式——
// 编辑层显示与展示一致），非契约要求。
//
// 编辑会话（editing 可写——设 true/false 进出；官方无此接口，Qool 扩展）：
// - **editing 是信号与行为的衔接点**：进入/结束意图（点击/聚焦/Enter/失焦/
//   程序化）只负责置 editing（唯一状态源），行为统一从 onEditingChanged
//   启动——true → Loader 绑定装配；false → 数据回流 + editingFinished——
//   程序化与交互路径行为一致。
// - 统一收尾（结束尝试）：编辑层 editingFinished（无 validator 无条件发
//   ——Enter/失焦全覆盖）→ wanna_stop_editing 判定（judge——常驻，不依赖
//   编辑层卸载时序）——接受替换 / 拒绝回退（text 不变）→ 结束。
// - Esc = 普通失焦（编辑层 Keys.onEscapePressed → focus=false），落入同一
//   收尾路径。无取消、无 Esc 区分。
//
// 契约差异（与 Qt 官方 TextField 对照）：
// - 官方 TextField 单层常驻输入（displayText 与编辑同一文本对象）；本类型
//   双层分离、displayText 只读派生、编辑会话状态机。
// - editing / editingStarted() / editingFinished() / accepted() / rejected()
//   为 Qool 扩展（官方无编辑会话开关与对应信号；官方 accepted 仅在 Enter
//   且可接受时发——本类型 accepted 为结束尝试判定结果，来源语义不同）。
// - 官方 API 兼容：textEdited（转发编辑层用户编辑事件——模拟官方语义）。
// - 裸控件：无壳层视觉（背景盒/标题/壳层 covers 由宿主包装 QoolControl
//   提供）——与 SpinBox 同定位。
//
// 待验证（调试时实测确认，2026-08-10）：
// - FocusScope 焦点回退：编辑层卸载（Loader 销毁）后焦点应自动回退到域内
//   本控件（Qt 惯例"控件保留焦点"）；若实测不回退，需显式 forceActiveFocus
//   回本体（卸载后无对象可释放焦点，焦点归位机制待实测确认）。
// - Loader active 绑定求值时机：onLoaded 装配依赖 item 已创建并入树（规避
//   "信号处理器内绑定延迟求值"——置 editing 当刻读 editLoader.item 不可靠）。
// - popup 等浮层关闭后焦点归还：浮层抢焦点使编辑层失焦收尾；关闭后 Qt 的
//   焦点恢复（lastActiveFocusItem 链）可能把焦点落回本控件——若落回将经
//   onActiveFocusChanged 自动重开会话。可能性记录（2026-08-10 审查）：
//   从未观察到实际发生（恢复分支依赖 lastActiveFocusItem 销毁状态），
//   真窗口实测确认。

/*!
    \qmltype EditableText
    \inqmlmodule Qool.Controls
    \inherits Control

    \brief 可编辑的 Text——Qool 双层强化版文本组件（展示层 + 编辑层 +
    编辑模型）。

    \b 定位：EditableText 是一个\textbf{可编辑的 Text}，\b{不是} Qt
    TextField 的替代实现——不承诺官方 TextField API 面。平时由展示组件
    （displayItem，默认 Text）常驻显示 text 的呈现形式（displayText），
    语义近似 Text（无点击聚焦、无编辑框方法）；点击内容区或聚焦（Tab）
    后进入编辑会话——编辑层（BasicTextField）覆盖编辑，语义近似
    TextInput 编辑，结束后卸载恢复展示。编辑会话的文本与校验归编辑模型
    （内部隐藏 TextInput），编辑层为无状态呈现。

    本类型是系列可编辑控件（ComboBox/SpinBox 等）编辑域的消费基底。

    \section1 接口兼容性

    继承 Qt Quick Templates 的 \l Control——官方 Control API 全部可用，
    宿主可参照官方文档。以下仅文档化 Qool 新增与差异部分。

    \section1 属性

    \qmlproperty string text
    主内容（保存形式，可写）。编辑结束经 textFromEditText 提交更新；
    平时经 displayTextFromText 派生展示。

    \qmlproperty string displayText
    展示文本——只读派生。Normal 回显下恒等于 displayTextFromText(text)；
    Password/PasswordEchoOnEdit 下为密码化结果（作用于插拔派生之后，
    逐字符替换为 passwordCharacter）；NoEcho 下为空串。见"密码回显"。

    \qmlproperty string editText
    编辑会话实时通道（别名编辑模型文本——单点事实源）。非编辑期跟随
    text；编辑期与编辑层双向同步（输入回写/程序化下发）。非编辑期写入
    无预设语义（不保证）。

    \qmlproperty var validator
    编辑校验（别名编辑模型消费）。挂接 Qt validator 家族照常
    （DoubleValidator/IntValidator/RegularExpressionValidator）。校验在
    编辑模型层进行——编辑层不挂 validator（其结束事件因此无条件发，
    判定由本类型统一执行，见"编辑会话"）。

    \qmlproperty bool editing
    编辑会话开关（Qool 扩展——官方无此接口）。true = 会话进行中（编辑
    层已装配就绪，宿主可读 editText）。宿主可设 true/false 进出会话；
    点击/聚焦/收尾路径亦驱动本属性。

    \b 注意：会话收尾期间状态机锁定——\l editingStarted 与
    \l editingFinished 信号处理器的执行窗口内设置本属性**不生效**（意图
    被丢弃）。宿主不要在 editingStarted / editingFinished / accepted /
    rejected 处理器中同步设置 editing；如需在拒绝后重开编辑，请延迟到
    事件处理之后（Qt.callLater）或由用户点击重新进入。

    \qmlproperty bool readOnly
    只读开关（纯行为——不触发样式变化）：true 时不启动会话（点击/聚焦
    空转）、不进 Tab 焦点链；显式会话（editing=true）可聚焦选中但不可
    编辑。会话进行中变为 true → 当前编辑被统一收尾判定（提交/拒绝）。

    \qmlproperty color color
    文本色——展示与编辑层共用（T.Control 无 color，Qool 扩展）。

    \qmlproperty int horizontalAlignment
    \qmlproperty int verticalAlignment
    文本对齐——展示与编辑层共用（编辑层经转发继承，切换无视觉跳动）。
    默认 AlignRight / AlignVCenter（QoolUI 控件内部文字惯例——右对齐）。

    \qmlproperty string inputMask
    \qmlproperty int inputMethodHints
    \qmlproperty int wrapMode
    输入掩码/输入法提示/换行模式——转发编辑层（官方 API 对齐），外部
    可设置并被响应。默认值与官方一致（空掩码 / ImhNone / NoWrap）。

    \qmlproperty bool selectByMouse
    鼠标选择开关——转发编辑层（官方 API 对齐）。默认 true（编辑会话
    中允许鼠标选择——selectAll 后键入覆盖的会话惯例）；外部可关闭。

    \qmlproperty int echoMode
    密码回显模式（转发编辑层——官方 TextInput API 对齐）：\c TextInput.Normal
    （默认，原文显示）/ \c TextInput.Password（掩码显示——键入新字符短暂
    明文，见 passwordMaskDelay）/ \c TextInput.NoEcho（不显示任何内容）/
    \c TextInput.PasswordEchoOnEdit（编辑期间明文、平时掩码）。非 Normal
    模式下 copy/cut 被禁用（编辑层内建——官方，防绕过密码特性）。见
    "密码回显"。

    \qmlproperty string passwordCharacter
    密码掩码字符（转发编辑层——官方 API 对齐）：Password/PasswordEchoOnEdit
    下掩码显示的字符。默认空串 = 透传平台主题字符（编辑层自动取平台
    字符）；\b 注意：非编辑态展示层（displayItem 掩码派生）在空串时
    fallback 固定字符"•"——两处默认可能不一致（编辑态平台字符 vs 非编辑
    态"•"），需两处一致时显式设置本属性。多字符取首字符；空串编辑层
    忽略（用平台默认）。

    \qmlproperty int passwordMaskDelay
    密码掩码延迟（转发编辑层——官方 API 对齐）：Password 模式键入新字符
    在掩码前明文显示的毫秒数。默认未设置（转发编辑层时保持其平台默认
    ——官方默认 600ms）——编辑态短暂明文确认键入。

    \qmlproperty Item displayItem
    展示组件（内容主体——Item 实例，几何自管）。默认 Text（绑定
    displayText/字体/颜色/对齐，anchors.fill）。宿主可整体替换（如换用
    其他呈现组件）。编辑时隐藏（opacity 切换——不卸载，会话结束恢复）。

    \qmlproperty var displayTextFromText
    插拔函数（默认恒等）：text（保存形式）→ 展示文本——展示过程转换
    （掩码/格式化等呈现变换）。派生类覆盖同名函数即生效（QML 函数遮蔽
    机制）。与 textFromEditText 语义独立（见下）。

    \qmlproperty var textFromEditText
    插拔函数（默认恒等）：编辑文本 → text（保存形式）——收尾过程转换
    （规范化：Trim/去空格等；直接编辑值语义）。与 displayTextFromText
    相互独立——不假设互为逆；实现为互逆运算是可行用法（编辑呈现形式
    ——编辑层显示与展示一致），非契约要求。

    \qmlproperty bool animationEnabled
    动画开关（父链继承——默认 Style.animationEnabled）：控制动画与高
    开销样式效果（"高性能模式 vs 完整效果"切换）。

    \section1 信号

    \qmlsignal editingStarted()
    进入编辑会话（编辑层已就绪，宿主可读 editText）。

    \qmlsignal editingFinished()
    编辑结束时刻宣告（对齐 TextInput 语义）——发生在判定结果信号
    （accepted/rejected）之前；接受时 text 已写入，宿主读值可靠。

    \qmlsignal accepted()
    \qmlsignal rejected()
    结束尝试的判定结果（Qool 扩展——独立信号，非内部转发）：accepted =
    输入被接受且已写入 text；rejected = 输入被拒未写入（宿主可提示）。
    仅输入内容与当前 text 不一致时触发（一致 = 无处理，不宣告）。

    \qmlsignal textEdited()
    用户编辑事件（转发编辑层——模拟官方 TextField 语义）：编辑会话中
    用户修改文本即发，与收尾判定无关。

    \section1 编辑会话

    进入：点击内容区 / 聚焦（Tab）/ 宿主设 editing = true。装配时编辑层
    填入当前 editText 并 selectAll（键入即整体替换）、抢焦点。

    结束尝试（Enter / 失焦 / Esc / 宿主设 editing = false）：编辑层
    editingFinished 无条件发（其不挂 validator）→ 本类型统一判定（编辑
    模型 acceptableInput）→ 接受：text = textFromEditText + accepted；
    拒绝：不写 + rejected；输入与当前 text 一致：无处理（两信号均不
    触发）→ editingFinished 宣告结束。Esc 等同普通失焦。

    判定不依赖编辑层生命周期（编辑模型常驻——程序化结束/编辑层已卸载
    亦可判定）。

    \section1 与 Qt TextField 的关系

    EditableText \b{不是} Qt TextField 的替代实现——不承诺官方 TextField
    API 面，宿主不应按官方 TextField 文档使用。它是 Qool 自己的可编辑
    Text 概念：

    \list
    \li 双层结构：展示层（displayItem，Text 语义）与编辑会话（BasicTextField
        覆盖编辑，TextInput 语义）分离；displayText 只读派生。
    \li 编辑会话状态机：editing / editingStarted() / editingFinished() /
        accepted() / rejected() 为 Qool 扩展——官方无编辑会话开关与
        对应信号（官方 accepted 仅在 Enter 且可接受时发；本类型 accepted
        为结束尝试判定结果，来源语义不同）。
    \li 裸控件：无壳层视觉（背景盒/标题/壳层 covers）——由宿主包装
        QoolControl 等提供（与 SpinBox 同定位）。
    \endlist

    \section1 密码回显

    设置 \c echoMode 为 \c TextInput.Password / \c TextInput.PasswordEchoOnEdit
    启用密码输入。掩码在两层生效：

    \list
    \li 展示层（非编辑态）：\c displayText 密码化派生——对
        displayTextFromText(text) 的结果逐字符替换为 \c passwordCharacter
        （空串时 fallback 固定字符"•"）。插拔点保留——密码化在其后。
    \li 编辑层（编辑会话）：真 TextInput 承担——\c Password 键入新字符
        短暂明文（\c passwordMaskDelay）后掩码；\c PasswordEchoOnEdit
        编辑期间明文、失去焦点后掩码。
    \endlist

    \b copy/cut 禁用：非 Normal 回显模式下，编辑层内建禁用 copy/cut
    （官方——防止以复制绕过密码特性）。

    \b passwordCharacter 默认：空串 = 透传平台主题字符。编辑层取平台
    字符；展示层 fallback"•"——两处默认可能不一致，需一致时显式设置
    \c passwordCharacter。

    \b readOnly + echoMode：非编辑态只读展示同样按掩码派生（展示层统一
    处理）——只读密码字段同样隐藏明文。

    \b NoEcho：displayText 为空串（完全不显示），最高安全——不可见
    输入内容，仅适用于确定不需确认输入的纯隐藏场景。
*/

T.Control {
    id: root

    /* 动画开关（父链继承——默认 Style.animationEnabled）：控制动画与
       高开销样式效果（仓库规范——"高性能模式 vs 完整效果"切换）。 */
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    /* 文本模型：主内容（可写）。编辑结束经 textFromEditText 提交更新；
       平时经 displayTextFromText 派生展示。 */
    property string text

    /* 展示文本：只读派生（插拔点 displayTextFromText；密码回显按 echoMode
       掩码化）。绑定块内直接引用 passwordCharacter/echoMode——建立依赖
       跟踪（函数体内引用不建立——必须写在绑定表达式块内）。派生规则：
       Normal → displayTextFromText(text)；NoEcho → 空串；
       Password/PasswordEchoOnEdit → 密码化 displayTextFromText(text) 结果
       （逐字符替换为 passwordCharacter；空时 fallback "•"）。密码化作用于
       插拔派生结果之后——插拔点保留（自定义保存→展示转换仍生效）。 */
    readonly property string displayText: {
        let base = displayTextFromText(root.text);
        if (root.echoMode === TextInput.Normal)
            return base;
        if (root.echoMode === TextInput.NoEcho)
            return "";
        // Password / PasswordEchoOnEdit：密码化派生结果（每源字符一个掩码
        // 字符——取 passwordCharacter 首字符，对齐 Qt 编辑层 TextInput
        // 语义"多字符取首字符"；空时 fallback "•"）
        let bullet = root.passwordCharacter.length > 0 ? root.passwordCharacter[0] : "•";
        return bullet.repeat(base.length);
    }

    /* 密码回显模式（转发编辑层——官方 TextInput API 对齐）：Normal（默认，
       原文显示）/ Password（掩码显示——键入新字符短暂明文见
       passwordMaskDelay）/ NoEcho（不显示任何内容）/ PasswordEchoOnEdit
       （编辑期间明文、平时掩码）。非 Normal 模式下编辑层内建禁用 copy/cut
       （官方——防绕过密码特性）。 */
    property int echoMode: TextInput.Normal

    /* 密码字符（转发编辑层——官方 API 对齐）：Password/PasswordEchoOnEdit
       掩码显示的字符。默认空串 = 透传平台主题字符（编辑层自动取平台字符）；
       展示层（displayItem 非编辑态掩码派生）在空串时 fallback 固定字符
       "•"——两处默认可能不一致（编辑态平台字符 vs 非编辑态"•"），需一致时
       显式设置本属性。多字符取首字符；空串编辑层忽略（用平台默认）。 */
    property string passwordCharacter

    /* 密码掩码延迟（转发编辑层——官方 API 对齐）：Password 模式键入新字符
       在掩码前明文显示的毫秒数。默认未设置（undefined）——转发编辑层时
       reset 到其平台默认（官方 TextInput 默认 600ms，官方文档未明写——
       实测确认）：编辑态短暂明文确认键入。 */
    property var passwordMaskDelay

    /* 编辑会话实时通道（alias judge.text——编辑模型单点）：非编辑期跟随
       text（judge 手动同步——见 pCtrl Connections）；编辑期与编辑层双向
       同步；非编辑写入无预设语义（不保证）。 */
    property alias editText: judge.text

    /* 编辑层校验：alias 直通 judge（编辑模型——单点事实源）。宿主挂
       Qt validator 家族照常（DoubleValidator/IntValidator/...）；编辑层
       不挂——其 accepted/editingFinished 因此无条件发（结束尝试全识别）。 */
    property alias validator: judge.validator

    /* 编辑会话开关（Qool 扩展）：true = 会话进行中（编辑层在场）。宿主
       设 true/false 进出会话；点击/聚焦/收尾路径亦驱动本属性。 */
    property bool editing: false

    /* 编辑开关（TextField 惯例命名，不提供 editable——反相冗余）：true =
       只读。不启动会话（点击/聚焦空转）；编辑层亦只读（显式会话可聚焦
       选中，不可编辑）。纯行为开关——不触发样式变化；会话进行中变 true
       时由 pCtrl Connections 统一收尾（见下）。 */
    property bool readOnly: false

    /* 文本色：display 与编辑层共用（T.Control 无 color，Qool 扩展）。 */
    property color color: Style.text

    // display 与编辑层共用（编辑层经转发继承——切换无视觉跳动）
    property int horizontalAlignment: Text.AlignRight
    property int verticalAlignment: Text.AlignVCenter

    /* 输入掩码（转发编辑层——官方 TextField API 对齐）：掩码限制输入
       字符格式；与 validator 的交互按 Qt 语义（宿主自管）。 */
    property string inputMask: ""

    /* 输入法提示（转发编辑层——官方 API 对齐）：影响软键盘/输入法行为。 */
    property int inputMethodHints: Qt.ImhNone

    /* 换行模式（转发编辑层——官方 API 对齐）：单行文本域默认 NoWrap。 */
    property int wrapMode: TextInput.NoWrap

    /* 鼠标选择开关（转发编辑层——官方 API 对齐）：默认 true——编辑会话
       中允许鼠标选择（selectAll 后键入覆盖的会话惯例）；外部可关闭。 */
    property bool selectByMouse: true

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
        visible: opacity > 0
        BasicTextBehavior on text {
            enabled: root.animationEnabled && !root.editing
        }
        BasicNumberBehavior on opacity {
            // 显式绑控件自身（而非依赖 Behavior 内部动态查 Style——父链
            // 覆盖可生效）
            enabled: root.animationEnabled
        }
    }

    /* 插拔函数（默认恒等）：text（保存形式）→ 展示文本派生——展示过程
       的转换（掩码/格式化等呈现变换）。宿主派生类覆盖同名函数即生效
       （QML 函数遮蔽语言机制，同 SpinBox 三钩子）——displayText 绑定调用
       动态解析，text 变化时走覆盖实现。与 textFromEditText **语义独立**
       （分属展示/收尾两个过程）——不假设互为逆；实现为互逆运算是可行
       用法（宿主希望编辑呈现形式时——编辑层显示与展示一致），非契约。 */
    property var displayTextFromText: function (text) {
        return text;
    }

    /* 插拔函数（默认恒等）：编辑文本 → text（保存形式）——收尾过程的
       转换（规范化：Trim/去空格等；直接编辑值语义——编辑层显示保存
       形式）。与 displayTextFromText **语义独立**（分属收尾/展示两个
       过程）——不假设互为逆；实现为互逆（编辑呈现形式）是可行用法，
       非契约。 */
    property var textFromEditText: function (text) {
        return text;
    }

    /* Qool 扩展会话信号：进入编辑会话（编辑层已就绪，宿主可读 editText）/
       结束编辑会话（编辑结束时刻宣告——发生在判定结果信号（accepted/
       rejected）之前；接受时 text 已写入，宿主读值可靠）/
       结束尝试判定结果（accepted：输入被接受且已写入 text；rejected：
       输入被拒未写入——宿主提示）——仅输入内容与当前 text 不一致时触发
       （一致 = 无处理，不宣告）。 */
    signal editingStarted
    signal editingFinished
    signal accepted
    signal rejected

    /* 用户编辑事件（转发编辑层 textEdited——模拟官方 TextField 语义）：
       编辑会话中用户修改文本即发——与收尾判定无关（转发而非独立判断）。 */
    signal textEdited

    // 点击聚焦/进编辑由 contentItem 的 TapHandler 实现（无需 activeFocusOnTap——
    // 该属性不存在）；Tab 聚焦需显式开启——T.Control 基座默认 false
    // （AbstractButton/文本域的默认 true 不适用于本基座）。readOnly 时不进
    // Tab 焦点链（只读展示不抢焦点——宿主按钮/包装控件的键盘焦点让位）；
    // 显式会话（editing=true）仍可聚焦选中。
    activeFocusOnTab: !root.readOnly
    font.pixelSize: Style.controlTextSize

    /* 隐式尺寸：T.Control 默认 implicit 不自动基于 background/contentItem
       （默认 0）——需显式公式（官方 Basic/Control.qml 同款）。语义：背景
       （透明尺寸件——下限）与内容（displayItem 尺寸）取大。 */
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)

    /* 编辑模型（常驻——纯逻辑对象，无渲染/无焦点参与）：
       - text：非编辑期跟随 root.text 经 pCtrl Connections 手动同步（不用
         声明绑定 + Binding 组件覆盖/恢复——其恢复时序（delayed + restoreMode）
         在编辑层卸载时不可靠，会残留会话文本）；编辑期由编辑层 onTextEdited
         回写；收尾显式恢复基准。
       - validator：root.validator alias 直通（本对象消费）。
       - acceptableInput：随文本实时校验——结束尝试判定直接读，不依赖
         编辑层生命周期（程序化结束/编辑层已卸载亦可判定）。 */
    TextInput {
        id: judge
        visible: false

        // 初始化同步：手动方案下无声明绑定（属性初始赋值不触发 changed——
        // Connections 不会为初始值同步）——此处补一次基准；后续由
        // Connections（非编辑期）/ onTextEdited（编辑期）/ 收尾恢复维护
        Component.onCompleted: judge.text = root.text
    }

    /* 逻辑对象：编辑会话状态机。editing 是信号与行为的衔接点——进入/结束
       意图（点击/聚焦/Enter/失焦/程序化）只负责置 editing（唯一状态源），
       行为统一从 onEditingChanged 启动（true → Loader 绑定装配；false → 数据
       回流 + editingFinished），程序化与交互路径行为一致。Connections 包装
       （而非 root 直接定义 on 方法）：信号处理不占 root 属性槽位——root 被
       继承时派生类可自行定义同名 handler，基类逻辑不被重写（并存）。 */
    SmartObject {
        id: pCtrl

        Connections {
            target: root
            function onEditingChanged() {
                if (root.editing && !pCtrl.internalEditing)
                    pCtrl.wanna_start_editing();

                if (!root.editing && pCtrl.internalEditing)
                    pCtrl.wanna_stop_editing();
            }
            function onActiveFocusChanged() {
                if (activeFocus && !root.editing && !root.readOnly)
                    pCtrl.wanna_start_editing();
            }
            // 非编辑期 judge.text 跟随 root.text（手动同步——编辑基准 =
            // 主内容原值；不触碰 displayTextFromText / textFromEditText 的
            // 介入点：展示派生与收尾转换仍走各自唯一调用点）
            function onTextChanged() {
                if (!pCtrl.internalEditing)
                    judge.text = root.text;
            }
            // readOnly 中途变 true（上层控件 editable 关闭等场景）：只读语义
            // 与"会话进行中"矛盾——统一收尾（判定流程完整走完——提交/拒绝
            // 判定 + 信号），不留悬挂编辑态。上层控件零代码（本控件自管）。
            function onReadOnlyChanged() {
                if (root.readOnly && pCtrl.internalEditing)
                    pCtrl.wanna_stop_editing();
            }
        }

        // judge（编辑模型）信号桥接：会话文本变化 → 下发编辑层（宿主程序化
        // 写 editText/收尾重置回显——同值守卫无循环）。
        Connections {
            target: judge
            function onTextChanged() {
                let field = editLoader.item;
                if (field)
                    field.text = judge.text;
            }
        }

        property bool internalEditing: false //editor存活

        // 收尾进行中标志：editing=false 会触发 onEditingChanged 桥接（条件
        // !editing && internalEditing——internalEditing 最后才置 false）——
        // 防递归重复收尾（否则同一收尾重复执行、信号重发）
        property bool finishing: false

        function wanna_start_editing() {
            internalEditing = true;
        }

        // 装配（Loader.onLoaded——item 已入树）：填 editText → selectAll
        // （键入即整体替换）→ 抢焦点（域内，不破坏外部焦点链）。
        function setup_editor() {
            let field = editLoader.item;
            if (field) {
                field.text = root.editText;
                field.selectAll();
                field.forceActiveFocus();
                field.opacity = 1;
            }
            //最终状态更新
            root.editing = true;
            root.editingStarted();
        }

        /* 统一收尾（结束尝试——编辑层 editingFinished / 程序化 editing=false
           触发）：判定在 judge（常驻模型——不依赖编辑层生命周期/卸载时序）。
           顺序：判定 → 接受则先写入 text（textFromEditText）→ 状态结束 +
           editingFinished（对齐 TextInput 编辑结束语义——发生在判定结果
           信号之前；接受时 text 已写入，宿主读值可靠）→ 判定结果宣告
           （accepted/rejected——输入与当前 text 一致 = 无处理，均不触发）。
           幂等守卫：同一结束尝试只收尾一次（Enter 与失焦可能同帧触发）。 */
        function wanna_stop_editing() {
            if (!internalEditing || finishing)
                return;
            finishing = true;

            let accepted = judge.acceptableInput;
            let changed = judge.text !== root.text; //一致 = 无处理
            if (accepted && changed)
                root.text = root.textFromEditText(judge.text);

            root.editing = false;
            root.editingFinished();

            // 编辑模型脱离"编辑中"窗口——**提前于判定信号**：accepted/rejected
            // 发出时若 internalEditing 仍 true，宿主/上层控件的命令式写回
            // （如 SpinBox 的 decimals 格式化回位、ComboBox 的 currentText
            // 拉回——同步执行于判定信号处理器内）会被 onTextChanged 的
            // internalEditing 守卫挡在 judge 之外——judge 与 text 脱同步固化，
            // 下次会话基准错乱、每轮往返误判 changed。提前卸载后写回正常
            // 回流 judge。
            internalEditing = false; //最后卸载（编辑层销毁——判定信号不再依赖编辑层）

            // 会话基准恢复：judge.text 回到主内容原值（非编辑期跟随的手动
            // 同步基准——下次会话初始无残留；接受时 root.text 已写入转换
            // 结果——恢复即新值）
            judge.text = root.text;

            if (changed) {
                if (accepted)
                    root.accepted();
                else
                    root.rejected();
            }

            finishing = false;
        }
    }//pCtrl

    background: Item {
        //透明背景，仅提供尺寸
        implicitHeight: 10
        implicitWidth: 10
    }

    contentItem: Item {
        id: contentContainer

        // 默认尺寸随展示内容（displayItem 几何自管；宿主自定义时以其隐式
        // 尺寸为准——implicitWidth 为内容宽，不受 anchors 拉伸影响）
        implicitWidth: root.displayItem ? root.displayItem.implicitWidth : 0
        implicitHeight: root.displayItem ? root.displayItem.implicitHeight : 0

        /* 编辑层：Loader 延迟加载 + 结束卸载（编辑会话状态隔离 + 大量实例
           资源节约）。呈现层——无状态：文本/校验在 judge（模型），本层只
           显示与捕获输入（回写 judge）。装配（填入 editText、selectAll、
           抢焦点）在 onLoaded——此时 item 已创建并入树，forceActiveFocus
           可靠（规避信号处理器内绑定延迟求值：置 editing 当刻 item 可能
           未就绪）。 */
        Loader {
            id: editLoader
            anchors.fill: parent
            // 由 internalEditing（编辑层存活）驱动——editing 是装配完成后的
            // 最终状态（setup_editor 才置 true），若绑 editing 则交互路径
            // （TapHandler/聚焦 → wanna_start_editing）永远等不到装配
            active: pCtrl.internalEditing
            onLoaded: pCtrl.setup_editor()
            sourceComponent: BasicTextField {
                // 显式锚定（Loader Sizing Behavior——Loader 锚定后 item 应自动
                // resize 恒等；显式 anchor 兜底，确保编辑层占满内容区）
                anchors.fill: parent
                font: root.font
                color: root.color
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment
                readOnly: root.readOnly
                enabled: root.enabled
                opacity: 0
                visible: opacity > 0
                selectByMouse: root.selectByMouse // 转发（官方 API 对齐——默认 true：selectAll 后键入覆盖的会话惯例）
                padding: 0 // 与 display 对齐（默认 Text 无 padding）——双层切换无位移
                // 点击聚焦已被外部管理（TapHandler 进编辑 / 装配
                // forceActiveFocus）——编辑层自身不抢焦点（避免冲突）
                activeFocusOnPress: false
                // 文本行为属性转发（官方 API 对齐——外部可设置并被响应）
                inputMask: root.inputMask
                inputMethodHints: root.inputMethodHints
                wrapMode: root.wrapMode
                // 密码回显转发（官方 API 对齐）：编辑层真 TextInput 承担
                // 密码显示/短暂明文/copy-cut 禁用（非 Normal 回显下内建
                // 失效——官方防绕过）；passwordMaskDelay 为 undefined 时
                // 编辑层 reset 到平台默认（透传）
                echoMode: root.echoMode
                passwordCharacter: root.passwordCharacter
                passwordMaskDelay: root.passwordMaskDelay

                // 输入 → judge.text 回写（编辑模型单点——用户输入即回写；
                // 不用 Binding 组件：其恢复机制（restoreMode + delayed）在
                // 编辑层卸载时可能丢失恢复（会话文本残留）——手动回写 +
                // 收尾显式恢复（wanna_stop_editing）确定性第一。程序化
                // text 赋值（setup_editor 填初始值）不发 textEdited——
                // 初始无污染）+ root.textEdited 转发（模拟官方语义）
                onTextEdited: {
                    judge.text = text;
                    root.textEdited();
                }

                // 结束尝试（唯一入口）：本层不挂 validator → editingFinished
                // 无条件发（Enter/失焦/Esc 全覆盖）——判定收尾在本类型层
                // （wanna_stop_editing——judge 判定）。不用 onAccepted：accepted
                // 是"接受"信号（结果），不是"结束输入"信号（起点）。
                onEditingFinished: pCtrl.wanna_stop_editing()

                // Esc = 普通失焦（= 失焦路径，落入统一收尾）。不下沉
                // BasicTextField：其定位是主题化默认 TextField，不掺行为决策；
                // Esc 收尾是行为型，属本层对"会话结束方式"的控制。
                Keys.onEscapePressed: focus = false

                // 淡入（setup_editor 0→1）；淡出不播放（收尾同回合卸载——
                // 编辑层直接移出场景，无帧边界）
                BasicNumberBehavior on opacity {
                    // 显式绑控件自身（避免 Behavior 内部动态查 Style）
                    enabled: root.animationEnabled
                }
            }
        }

        // 点击进编辑（display 区域）：readOnly/会话中禁用（编辑层自理点击，
        // 同时天然让位 IME——官方 inputMethodComposing 语义要求 composing
        // 期间点击交输入法编辑预编辑文本）。进入意图 = 置 editing。
        TapHandler {
            enabled: !root.readOnly && !pCtrl.internalEditing
            onTapped: pCtrl.wanna_start_editing()
        }

        // 悬停光标提示：IBeam（文本域惯例）；NoButton 不拦截点击（TapHandler
        // 负责进编辑——编辑会话中 TapHandler 禁用、编辑层自理）。只读时不
        // 提示（不可编辑——IBeam 误导）
        MouseArea {
            anchors.fill: parent
            enabled: !root.readOnly
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.IBeamCursor
        }
    }//contentItem

    // displayItem 置入内容层：宿主内联声明实例默认 parent = 控件根，需重
    // parent；几何不动（自管）。target 为绑定——宿主替换 displayItem 时
    // 新实例同样置入。
    Binding {
        when: root.displayItem
        target: root.displayItem
        property: "parent"
        value: contentContainer
    }

    // 编辑时隐藏展示层（不卸载——会话结束恢复，无重建开销；opacity 切换
    // 为动画留位——Behavior 暂不加）
    Binding {
        target: root.displayItem
        property: "opacity"
        value: pCtrl.internalEditing ? 0 : 1
    }

    Component.onCompleted: {
        pCtrl.internalEditing = root.editing;
    }
}
