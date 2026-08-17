import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls as Q
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
// 编辑域（2026-08-10 迁移）：内容区常驻 Qool EditableText（双层强化版——展示层
// + 编辑会话自管）。本控件只做 value ↔ text 映射与信号转发（pCtrl）：
// - 显示：value → textFromValue 格式化喂入 textField.text（命令式同步——
//   用户裁定不采用属性绑定：EditableText 收尾内部写回 text 会打断外部绑定）。
// - 编辑接受：textField.accepted → 读收尾后的 text → valueFromText 映射 →
//   value（值变补 valueModified）→ 透传 root.accepted()；映射失败（非有限数）
//   不写 value——按拒绝回退（现状契约：不写脏数据）。
// - 编辑拒绝：textField.rejected → 透传 root.rejected()（value 不变、
//   textField.text 未写回——显示自然回退）。
// - 编辑中按指示器：textField.editing = false（同步收尾）→ 模板步进。
// - editable 中途关闭：EditableText 自管（readOnly → 统一收尾判定）——零代码。
//
// 契约差异（与 Qt 官方默认实现对照）：
// - inputMethodHints 官方默认 ImhDigitsOnly（虚拟键盘上不允许小数点/负号），
//   Qool 改为 Qt.ImhFormattedNumbersOnly，支持小数与负号输入。
// - 编辑提交/回退：官方失焦时把文本直接解析并夹紧写入 value（无效文本会被
//   解析为 0 之类）；本实现校验不通过（acceptableInput=false）或解析失败
//   （非有限数）时回退原值，不写脏数据（判定在编辑域 EditableText 层——
//   accepted/rejected 信号透出，宿主可感知）。
// - 编辑中滚轮：官方模板无编辑态守卫，且文本域不消费滚轮事件（冒泡到控件），
//   编辑态滚轮照样步进（value 步进 + valueModified）——但提交按编辑会话
//   文本（judge）重解析，步进值在提交时被编辑文本回退（与官方单层语义
//   差异：官方显示与编辑同一文本对象，提交即步进后值）。
// - 编辑中指示器点击：官方保持编辑态继续步进（文本域可能显示过期文本）；
//   本实现按下指示器即先结束编辑（统一收尾——提交判定），再由模板自身的
//   按下重复逻辑步进——提交 + 步进顺序保证不丢输入（见 up/down Connections）。
//
// 三钩子哲学（能力开放而非功能内置）：currentValue（默认绑定 value，可覆写）、
// textFromValue/valueFromText（官方 function 属性，覆写即生效——自定义显示/
// 解析格式；旧 displayTextOverride 实例级覆写通道已移除——见属性注释）、
// increase/decrease（官方 QML 方法，覆写即生效）。

T.DoubleSpinBox {
    id: root

    /* 三钩子之一：currentValue。默认绑定 value（跟随步进/提交），宿主赋值
       即断开绑定（QML 普通可写属性语义），用于"显示值独立于内部值"的场景。 */
    property var currentValue: root.value

    /* 三钩子之二：显示文本（无属性——经编辑域 EditableText 的 text 喂入消费：
       显示 = value → textFromValue 格式化（pCtrl 命令式同步）。宿主自定义
       显示经覆写官方 textFromValue/valueFromText 配对（派生类——官方机制）
       实现——不再需要实例级覆写通道属性（旧 displayTextOverride 已移除）。 */

    /* Qool 扩展：编辑中文本回写口（与 ComboBox.editText 同风格——编辑域
       为 EditableText 实例，tf.editText 变化命令式同步至此——单向 tf → root）。
       模板无 editText 属性；供宿主观察编辑过程。 */
    property string editText

    /* Qool 扩展：编辑结束尝试的判定结果透传（编辑域 EditableText 的判定——
       accepted：输入通过校验且被解析为有限数（value 已更新，宿主读 value
       可靠）；rejected：校验不通过或解析失败（value 不变）。官方
       T.DoubleSpinBox 无此信号——须显式声明（pCtrl Connections 调用）。 */
    signal accepted
    signal rejected

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

    /* 逻辑对象：value ↔ text 映射与编辑结果处理（SmartObject——仓库逻辑
       容器惯例；QtObject 无法承载独立对象）。编辑会话状态机由 EditableText
       承担（双层自管）——本对象只做映射与信号转发。 */
    SmartObject {
        id: pCtrl

        Connections {
            target: root
            // 步进/程序化 value 变化 → 显示喂入（textFromValue 官方格式化；
            // 命令式——用户裁定不采用属性绑定：EditableText 收尾内部写回 text
            // 会打断外部绑定——见文件头）
            function onValueChanged() {
                textField.text = root.textFromValue(root.value, root.locale, root.decimals);
            }
        }

        Connections {
            target: textField
            // 编辑中文本回写（Qool 扩展 editText——单向 tf → root，与
            // ComboBox 同风格）
            function onEditTextChanged() {
                root.editText = textField.editText;
            }
            // 编辑接受：读收尾后的 text（= textFromEditText(judge.text)——EditableText
            // 内部默认恒等转换；消费者是实例化非继承，不覆写该插拔点）→
            // valueFromText 映射 → 写 value（值实际变化时补发 valueModified
            // ——官方语义）→ 显示拉回（值未变时 valueChanged 不触发——此处
            // 显式格式化回位）→ 透传 accepted（宿主读 value 可靠）。映射
            // 失败（valueFromText 返回非有限数——自定义覆写场景）不写 value
            // ——按拒绝路径回退（现状契约：不写脏数据）。
            function onAccepted() {
                let parsed = root.valueFromText(textField.text, root.locale);
                if (isFinite(parsed)) {
                    let old = root.value;
                    root.value = parsed;
                    if (root.value !== old)
                        root.valueModified();
                    textField.text = root.textFromValue(root.value, root.locale, root.decimals);
                    root.accepted();
                } else {
                    root.rejected();
                }
            }
            // 编辑拒绝：value 不变、textField.text 未写回（显示自然回退——
            // 编辑层卸载恢复展示层旧值）→ 透传（宿主可提示）
            function onRejected() {
                root.rejected();
            }
        }
    }//pCtrl

    // editable 中途关闭：编辑域 EditableText 自管（readOnly 变 true → 统一
    // 收尾判定）——本控件零代码

    /* 编辑中按下指示器：先结束编辑（textField.editing = false——同步触发
       EditableText 统一收尾：判定提交/拒绝）再由模板的按下重复逻辑步进
       （长按 300ms 后每 100ms 步进；快速点击在释放时步进一次）——
       "结束编辑并步进"，提交 + 步进顺序保证不丢输入。键盘 ↑/↓ 在编辑态
       由文本域处理，不会走到这里（模板 handleKeyPressEvent 设置 pressed
       仅在控件自身收键时）。 */
    Connections {
        target: root.up
        function onPressedChanged() {
            if (root.up.pressed && textField.editing)
                textField.editing = false;
        }
    }

    Connections {
        target: root.down
        function onPressedChanged() {
            if (root.down.pressed && textField.editing)
                textField.editing = false;
        }
    }

    /* 官方 padding 机制：左右按指示器宽度预留（down 左、up 右），内容区
       （contentItem）自动在 padding 内，不压指示器——照 Basic 默认实现。 */
    leftPadding: root.mirrored ? root.up.indicator.width : root.down.indicator.width
    rightPadding: root.mirrored ? root.down.indicator.width : root.up.indicator.width

    /* up/down 指示器：HalfCrystal（三角版 Crystal——方向箭头；左右方向：
       右条 ▶（增加）、左条 ◀（减少））。机制（对照官方 Basic 默认实现）：
       up/down 是模板安装的 SpinButton（全宽上下半布局，模板管几何与命中
       分区——up 上半、down 下半，到达 from/to 边界自动禁用）；indicator
       是按钮的内容项，anchors.centerIn 居中于按钮。注意视觉与命中的官方
       语义：指示器只是方向装饰，命中始终按按钮分区（点右条上半命中 up）。
       隐藏时用 visible 关断（Qt Quick 事件系统不向不可见项派发指针事件 →
       隐藏即不可点；// 行为待验证：模板 contains() 是否带可见性检查，实测
       确认）。淡入保留动画（visible 翻转后 opacity 0→1 经
       BasicNumberBehavior），淡出随 visible 立即消失（隐藏优先于淡出
       动画）。 */
    up.indicator: HalfCrystal {
        borderWidth: 0
        color: Style.buttonText
        // 显式尺寸（HalfCrystal 默认 20×20 超出半高按钮——12 与旧指示器
        // 同尺寸，位置公式不变）
        width: 12
        height: 12
        // 右缘条（镜像左缘）——按钮全宽（模板分区 up 上半），须显式 x
        // 钉在右缘（anchors.centerIn 会居中于全宽按钮——水平居中错误）
        x: root.mirrored ? 0 : parent.width - width
        y: (parent.height - height) / 2
        // 左右方向：右条 = 增加（▶ 右箭头）
        direction: root.mirrored ? Qore.W : Qore.E
        visible: root.hovered || root.activeFocus
        opacity: visible ? 1 : 0
        BasicNumberBehavior on opacity {}
    }//up.indicator

    down.indicator: HalfCrystal {
        borderWidth: 0
        color: Style.buttonText
        width: 12
        height: 12
        // 左缘条（镜像右缘）——按钮全宽（模板分区 down 下半），须显式 x
        // 钉在左缘（anchors.centerIn 会居中于全宽按钮——水平居中错误）
        x: root.mirrored ? parent.width - width : 0
        y: (parent.height - height) / 2
        // 左右方向：左条 = 减少（◀ 左箭头）
        direction: root.mirrored ? Qore.E : Qore.W
        visible: root.hovered || root.activeFocus
        opacity: visible ? 1 : 0
        BasicNumberBehavior on opacity {}
    }//down.indicator

    contentItem: Item {
        id: contentContainer
        implicitWidth: textField.implicitWidth
        implicitHeight: textField.implicitHeight

        // 编辑域：常驻 EditableText（双层——展示层 + 编辑会话自管）。editable
        // 经 readOnly 控制（绑定）：非可编辑只读展示（点击空转——指示器
        // 步进照常）；可编辑点击/聚焦进会话（EditableText 自带 TapHandler/
        // activeFocusOnTab）。显示文本由 pCtrl 命令式喂入（value →
        // textFromValue）——见 pCtrl Connections。padding 由控件级
        // leftPadding/rightPadding 避让指示器（内容区已在 padding 内）。
        Q.EditableText {
            id: textField
            anchors.fill: parent

            readOnly: !root.editable
            font: root.font
            color: root.Style.text
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment

            validator: root.validator
            inputMethodHints: root.inputMethodHints
        }

        // 初始基准（Connections 不为属性初始值触发——value 初始赋值不触发
        // onValueChanged）
        Component.onCompleted: textField.text = root.textFromValue(root.value, root.locale, root.decimals)
        // 焦点进入兜底：模板在 editable 时于 focusIn 强制焦点到 contentItem
        // （且对 contentItem 设置 activeFocusOnTab）——Tab/键盘聚焦路径落
        // 在此 Item 上——转发进编辑会话（EditableText 的 editing 开关——装配
        // 由 onEditingChanged 启动）。EditableText 自身的 activeFocusOnTab/
        // 点击路径自管——双路径都进会话（对齐官方：聚焦即编辑）。
        onActiveFocusChanged: if (root.editable && !textField.editing && activeFocus)
            textField.editing = true
    }//contentItem

    // 裸控件无背景 → 无 containmentMask（模板默认），hover 反馈照常
    hoverEnabled: true

    // 裸控件不提供壳层三件套（ControlPressedCover/HighlightCover/LockedCover
    // 是完整包装控件的整体反馈层，属壳层行为——宿主包装 QoolControl 时由壳
    // 提供）；本体的交互反馈即指示器自身的状态色与按需淡入（见上）。
}
