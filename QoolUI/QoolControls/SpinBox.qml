import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls.Components
import Qool

// SpinBox：Qool.Controls 系列第二个控件（基座 T.DoubleSpinBox，官方 API 兼容）。
//
// 定位：**裸步进器，不内置 QoolControl 壳**。本控件不含背景盒/标题/标签/
// 内容内边距（那是 BasicControl/QoolControl 的壳层能力）——宿主需要壳时
// 自行包装（如装入 QoolControl；包装接口待验证——contentItem 外部赋值实测
// 被 QML 引擎拒绝（Invalid property assignment），2026-08-09 记录，壳层
// 设计时再定）。本控件只负责数值步进本身：文本、指示器、编辑、步进反馈
// （指示器状态色与按需淡入；壳层 covers 三件套不提供，属包装控件）。
//
// 设计意图：
// - 点击覆盖式编辑：与 ComboBox 的常驻编辑域不同，本控件平时用 Text 显示
//   displayText；点击内容区（或 Tab/焦点进入）后 Loader 激活 BasicTextField
//   覆盖编辑（selectAll 后键入即整体替换），Enter 或失焦提交、失败回退，随后
//   恢复 Text。编辑接线参考 v3 TextLineEdit 的 TapHandler 模式。
// - 按需呈现指示器：up/down 指示器为两个 Rectangle 占位（不实现箭头图形），
//   右侧上下堆叠；仅 hovered/activeFocus 时淡入，平时隐藏——Qool 风格：
//   动态呈现附加内容。隐藏时 visible=false 使点击无效（见下）。
// - 三钩子哲学（能力开放而非功能内置）：currentValue（默认绑定 value，可覆写）、
//   displayTextOverride（显示文本覆写，形态见下）、textFromValue/valueFromText/
//   increase/decrease（官方 function 属性/方法，覆写即生效，零代码）。
//
// 契约差异（与 Qt 官方默认实现对照）：
// - inputMethodHints 官方默认 ImhDigitsOnly（虚拟键盘上不允许小数点/负号），
//   Qool 改为 Qt.ImhFormattedNumbersOnly，支持小数与负号输入。
// - 编辑提交/回退：官方失焦时把文本直接解析并夹紧写入 value（无效文本会被
//   解析为 0 之类）；本实现校验不通过（acceptableInput=false）或解析失败
//   （非有限数）时回退原值，不写脏数据。
// - 编辑中滚轮：官方模板无编辑态守卫，且文本域不消费滚轮事件（冒泡到控件），
//   故编辑态滚轮照样步进；本实现同款（BasicTextField 亦不消费滚轮）。
// - 编辑中指示器点击：官方保持编辑态继续步进（文本域可能显示过期文本）；
//   本实现按下指示器即先提交结束编辑，再由模板自身的按下重复逻辑步进——
//   提交 + 步进顺序保证不丢输入（见 pCtrl.commit_edit 旁的 Connections）。
//
// 机制结论（已对照官方实现核实，2026-08-09）：
// - editingFinished：T.DoubleSpinBox 模板无此信号（官方信号清单仅
//   valueModified 等，无 editingFinished）——不存在"模板自动发"的问题，
//   无需手动补发；BasicTextField（T.TextField）自身的 editingFinished 在
//   Enter/失焦时照常发出（本实现用 onAccepted/onActiveFocusChanged 收口，
//   二者互斥不会重复提交）。
// - displayText 覆写形态：官方 displayText 是 FINAL 只读属性，QML 派生类
//   重声明同名属性会被引擎拒绝（Cannot override FINAL property），故用
//   displayTextOverride 通道：非空优先显示，空则回落官方 displayText。
// - Loader 识别缺口：模板按 contentItem 是否直接为 TextInput 识别编辑域
//   （qobject_cast），Loader 包裹下识别不到——displayText 不随输入更新、
//   Enter/失焦的自动提交（updateValue 读 contentItem.text）全部失效，
//   故编辑文本须手动回写（editText）与手动提交（commit_edit）。
// - increase()/decrease() 官方文档列明为 QML 方法，派生类声明同名函数即可
//   遮蔽（QML 语言机制）；注意模板内部步进（指示器/键盘/滚轮）走 C++ 实现，
//   覆写仅影响 QML 侧显式调用。

T.DoubleSpinBox {
    id: root

    /* 三钩子之一：currentValue。默认绑定 value（跟随步进/提交），宿主赋值
       即断开绑定（QML 普通可写属性语义），用于"显示值独立于内部值"的场景。 */
    property var currentValue: root.value

    /* 三钩子之二：显示文本覆写。displayText 是模板 FINAL 只读属性无法遮蔽
       （见文件头机制结论），故以此通道开放：非空时优先显示，空则回落官方
       displayText（= textFromValue(value, decimals, locale)）。 */
    property string displayTextOverride

    /* Qool 扩展：编辑中文本回写口。模板无 editText 属性（与 ComboBox 不同），
       因 Loader 识别缺口（见文件头）displayText 不随输入更新，onTextEdited
       手动回写至此，供宿主观察编辑过程。 */
    property string editText

    // 内容对齐（裸控件自身能力）
    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter

    /* 契约差异：官方默认 ImhDigitsOnly（见文件头）。宿主后续赋值仍可覆盖本默认。 */
    inputMethodHints: Qt.ImhFormattedNumbersOnly

    /* 默认校验器照官方 Basic 样式：bottom/top 按 from/to 取 min/max
       （支持 from>to 的倒置范围），decimals 限制输入精度。 */
    validator: DoubleValidator {
        locale: root.locale.name
        bottom: Math.min(root.from, root.to)
        top: Math.max(root.from, root.to)
        decimals: root.decimals
    }

    font.pixelSize: Style.controlTextSize

    /* 裸控件：背景仅作尺寸机制，无壳视觉。T 模板无默认 background
       （null），官方默认实现依赖背景的隐式尺寸计算控件默认大小——故保留
       透明 Item 撑起默认尺寸（宿主包装 QoolControl 时，壳背景覆盖其上）。 */
    background: Item {
        implicitWidth: 100
        implicitHeight: 35
    }

    // 官方布局公式：默认大小 = max(背景 + insets, 内容 + padding)
    // （内容含文本与右侧指示器预留；指示器在背景宽度内由模板定位）
    implicitWidth: {
        const w1 = leftInset + implicitBackgroundWidth + rightInset;
        const w2 = leftPadding + implicitContentWidth + rightPadding;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        const h1 = topInset + implicitBackgroundHeight + bottomInset;
        const h2 = topPadding + implicitContentHeight + bottomPadding;
        return Math.max(h1, h2);
    }

    /* 逻辑对象：编辑状态机。 */
    QtObject {
        id: pCtrl

        property bool editing: false

        // 进入编辑：Loader 激活（同步创建 BasicTextField）→ 填入当前显示
        // 文本（displayText 或覆写）→ selectAll（键入即整体替换）→ 抢焦点。
        // 先置 editing=true 再抢焦点，避免 activeFocus 抖动触发重复进入。
        function start_edit() {
            if (pCtrl.editing || !root.editable)
                return
            pCtrl.editing = true
            let field = textFieldLoader.item
            if (!field)
                return
            field.text = root.displayTextOverride.length ? root.displayTextOverride : root.displayText
            field.selectAll()
            field.forceActiveFocus()
        }

        // 提交（Enter/失焦/编辑中按指示器统一入口）：校验通过且解析为有限数
        // 才写入 value；值实际变化时补发 valueModified——官方模板的提交路径
        // （Enter/失焦 → updateValue）因 Loader 识别缺口失效（见文件头），
        // 手动补发以保持官方"用户文本提交触发 valueModified"语义，不重复
        // （值未变不发；模板其他路径不参与本次提交）。校验/解析失败回退原值。
        function commit_edit() {
            if (!pCtrl.editing)
                return
            let field = textFieldLoader.item
            if (field && field.acceptableInput) {
                let old = root.value
                let parsed = root.valueFromText(field.text, root.locale)
                if (isFinite(parsed)) {
                    root.value = parsed
                    if (root.value !== old)
                        root.valueModified()
                }
            }
            end_edit()
        }

        // 结束编辑：先关状态（令失焦回调空转，防重入）再释放焦点，Loader
        // active=false 销毁文本域，Text 恢复显示。不抢焦点——若焦点因点击
        // 他处而失去，则自然留在被点击处。
        function end_edit() {
            if (!pCtrl.editing)
                return
            pCtrl.editing = false
            let field = textFieldLoader.item
            if (field)
                field.focus = false
        }
    }//pCtrl

    // editable 中途关闭：收尾当前编辑（提交或回退），避免编辑态悬挂
    onEditableChanged: if (!root.editable && pCtrl.editing)
                           pCtrl.commit_edit()

    /* 编辑中按下指示器：先提交结束编辑，再由模板的按下重复逻辑步进
       （长按 300ms 后每 100ms 步进；快速点击在释放时步进一次）——
       "结束编辑并步进"，见文件头契约差异。键盘 ↑/↓ 在编辑态由文本域
       处理，不会走到这里（模板 handleKeyPressEvent 设置 pressed 仅在
       控件自身收键时）。 */
    Connections {
        target: root.up
        function onPressedChanged() {
            if (root.up.pressed && pCtrl.editing)
                pCtrl.commit_edit()
        }
    }

    Connections {
        target: root.down
        function onPressedChanged() {
            if (root.down.pressed && pCtrl.editing)
                pCtrl.commit_edit()
        }
    }

    /* 官方 padding 机制：左右按指示器宽度预留（down 左、up 右），内容区
       （contentItem）自动在 padding 内，不压指示器——照 Basic 默认实现。 */
    leftPadding: root.mirrored ? root.up.indicator.width : root.down.indicator.width
    rightPadding: root.mirrored ? root.down.indicator.width : root.up.indicator.width

    /* up/down 指示器：两个 Rectangle 占位（不实现箭头图形，位置留给后续
       形态实现）。机制（对照官方 Basic 默认实现）：up/down 是模板安装的
       SpinButton（全宽上下半布局，模板管几何与命中分区——up 上半、down
       下半，到达 from/to 边界自动禁用）；indicator 是按钮的内容项，视觉
       坐标用控件参照（官方即 control.width/control.height 写法，按钮 x=0
       全宽时与 parent 参照等价），画成左右全高条（官方默认形态：− 左 + 右）。
       注意视觉与命中的官方语义：指示器只是方向装饰，命中始终按按钮分区
       （点左条上半命中 up）。隐藏时用 visible 关断（Qt Quick 事件系统不向
       不可见项派发指针事件 → 隐藏即不可点；// 行为待验证：模板 contains()
       是否带可见性检查，实测确认）。
       淡入保留动画（visible 翻转后 opacity 0→1 经 BasicNumberBehavior），
       淡出随 visible 立即消失（隐藏优先于淡出动画）。 */
    up.indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: root.mirrored ? 0 : root.width - width
        height: root.height
        radius: 4
        color: enabled ? (root.up.pressed ? root.Style.highlight
                        : root.up.hovered ? root.Style.mid
                        : root.Style.controlBackgroundColor)
                       : root.Style.mid
        border.width: 1
        border.color: root.Style.controlBorderColor
        visible: root.hovered || root.activeFocus
        opacity: visible ? 1 : 0
        BasicNumberBehavior on opacity {}
    }//up.indicator

    down.indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: root.mirrored ? root.width - width : 0
        height: root.height
        radius: 4
        color: enabled ? (root.down.pressed ? root.Style.highlight
                        : root.down.hovered ? root.Style.mid
                        : root.Style.controlBackgroundColor)
                       : root.Style.mid
        border.width: 1
        border.color: root.Style.controlBorderColor
        visible: root.hovered || root.activeFocus
        opacity: visible ? 1 : 0
        BasicNumberBehavior on opacity {}
    }//down.indicator

    contentItem: Item {
        id: contentContainer

        implicitWidth: simpleText.implicitWidth
        implicitHeight: simpleText.implicitHeight

        Text {
            id: simpleText
            text: root.displayTextOverride.length ? root.displayTextOverride : root.displayText
            font: root.font
            enabled: root.enabled
            color: root.Style.buttonText
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            anchors.fill: parent

            visible: !pCtrl.editing
            BasicTextBehavior on text {}
        }

        Loader {
            id: textFieldLoader
            anchors.fill: parent
            active: pCtrl.editing
            sourceComponent: BasicTextField {
                id: field

                font: root.font
                enabled: root.enabled
                color: root.Style.text
                validator: root.validator
                inputMethodHints: root.inputMethodHints
                selectByMouse: true // 编辑态固定允许鼠标选择（selectAll 后键入覆盖）
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment

                // Loader 识别缺口（见文件头）：文本须手动回写 editText，
                // 模板不会同步 displayText
                onTextEdited: root.editText = text

                // Enter 提交：onAccepted 仅在校验通过（或 fixup 后）时发出，
                // 失败路径由 commit_edit 的 acceptableInput 判据回退
                onAccepted: pCtrl.commit_edit()

                // 失焦提交（含窗口失活）；commit_edit 内部以 editing 状态防重入
                onActiveFocusChanged: if (!activeFocus)
                                          pCtrl.commit_edit()
            }
        }

        // 点击覆盖入口：仅负责进入编辑。编辑期间禁用（文本域自理点击），
        // 同时天然让位 IME——官方 inputMethodComposing 语义要求 composing
        // 期间点击事件交由输入法编辑预编辑文本，本实现编辑态即关闭本处理器，
        // 不会出现"点击重开编辑销毁预编辑文本"的干扰
        TapHandler {
            enabled: root.editable && !pCtrl.editing
            onTapped: pCtrl.start_edit()
        }

        // 焦点进入兜底：模板在 editable 时于 focusIn 强制焦点到 contentItem
        // （且对 contentItem 设置 activeFocusOnTab），两种路径都落在此 Item
        // 上——借此在 Tab/键盘聚焦时同样进入编辑（对齐官方：聚焦即编辑）
        onActiveFocusChanged: if (root.editable && !pCtrl.editing && activeFocus)
                                  pCtrl.start_edit()
    }//contentItem

    // 裸控件无背景 → 无 containmentMask（模板默认），hover 反馈照常
    hoverEnabled: true

    // 裸控件不提供壳层三件套（ControlPressedCover/HighlightCover/LockedCover
    // 是完整包装控件的整体反馈层，属壳层行为——宿主包装 QoolControl 时由壳
    // 提供）；本体的交互反馈即指示器自身的状态色与按需淡入（见上）。
}
