import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool

T.Control {
    id: root

    property string text

    /* 只读派生（规则见 EditableText.md）。绑定块内直接引用
       passwordCharacter/echoMode——建立依赖跟踪（函数体内引用不建立） */
    readonly property string displayText: {
        let base = displayTextFromText(root.text);
        if (root.echoMode === TextInput.Normal)
            return base;
        if (root.echoMode === TextInput.NoEcho)
            return "";
        let bullet = root.passwordCharacter.length > 0 ? root.passwordCharacter[0] : "•";
        return bullet.repeat(base.length);
    }

    property int echoMode: TextInput.Normal

    property string passwordCharacter

    property var passwordMaskDelay

    property alias editText: judge.text

    property alias validator: judge.validator

    property bool editing: false

    property bool readOnly: false

    property color color: Style.text

    property int horizontalAlignment: Text.AlignRight
    property int verticalAlignment: Text.AlignVCenter

    property string inputMask: ""

    property int inputMethodHints: Qt.ImhNone

    property int wrapMode: TextInput.NoWrap

    property bool selectByMouse: true

    property Item displayItem: Text {
        text: root.displayText
        font: root.font
        color: root.color
        enabled: root.enabled
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        visible: opacity > 0
        BasicTextBehavior on text {
            enabled: root.Style.animationEnabled && !root.editing
        }
        BasicNumberBehavior on opacity {
            // 显式绑控件自身（而非依赖 Behavior 内部动态查 Style——父链
            // 覆盖可生效）
            enabled: root.Style.animationEnabled
        }
    }

    property var displayTextFromText: function (text) {
        return text;
    }

    property var textFromEditText: function (text) {
        return text;
    }

    signal editingStarted
    signal editingFinished
    signal accepted
    signal rejected

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
            z: -1   // 编辑层沉底：叠放最底层——显示层（displayItem）在上
                    // （编辑时经 opacity 隐藏露出编辑层），任何情况下编辑
                    // 层不遮挡显示层之上内容
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
                selectByMouse: root.selectByMouse
                padding: 0 // 与 display 对齐（默认 Text 无 padding）——双层切换无位移
                // 点击聚焦已被外部管理（TapHandler 进编辑 / 装配
                // forceActiveFocus）——编辑层自身不抢焦点（避免冲突）
                activeFocusOnPress: false
                inputMask: root.inputMask
                inputMethodHints: root.inputMethodHints
                wrapMode: root.wrapMode
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
                    enabled: root.Style.animationEnabled
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

    // displayItem 置入控件根（Binding target——宿主替换 displayItem 时新实例
    // 同样置入；与 contentItem 同父，GeoLocker 坐标系语义直观）
    Binding {
        when: root.displayItem
        target: root.displayItem
        property: "parent"
        value: root
    }

    // displayItem 几何统一锁定到内容容器（GeoLocker——宿主覆写无需声明
    // 几何；parent 已是 root，anchors.fill 会铺满控件含背景区）
    GeoLocker {
        target: root.displayItem
        lockTo: root.contentItem
    }

    Binding {
        target: root.displayItem
        property: "opacity"
        value: pCtrl.internalEditing ? 0 : 1
    }

    Component.onCompleted: {
        pCtrl.internalEditing = root.editing;
    }
}
