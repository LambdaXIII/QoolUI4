import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls.Components
import Qool.Controls as Q
import Qool

/*!
    \qmltype ComboBox
    \inqmlmodule Qool.Controls
    \brief 基于 QtQuick.Templates.ComboBox 的下拉选择框，支持可编辑文本与可配置的弹出方向。

    ComboBox 是按钮与弹出列表的组合控件，用于从一组选项中选择一项。
    本类型继承 QtQuick.Templates.ComboBox，接口与 QtQuick.Controls.ComboBox
    完全兼容——\c model、\c currentIndex、\c currentText、\c editable、
    \c editText、\c accepted()、\c find()、\c validator 等 Qt 官方 API
    全部可用，宿主可参照 Qt 官方文档使用。在官方接口之上，本类型提供
    外观定制（\c backgroundSettings、\c title、\c label）、内容内边距
    （\c contentPadding 系列）与弹出方向控制（\c popupDirection）。

    \section1 属性文档

    \qmlproperty string ComboBox::title
    标题文字，透传至背景盒顶部显示。

    \qmlproperty string ComboBox::label
    标签文字，透传至背景盒内部显示。

    \qmlproperty real ComboBox::contentPadding
    内容区四边统一内边距，默认 0。

    \qmlproperty real ComboBox::contentTopPadding
    \qmlproperty real ComboBox::contentBottomPadding
    \qmlproperty real ComboBox::contentLeftPadding
    \qmlproperty real ComboBox::contentRightPadding
    内容区单边内边距，覆盖 \c contentPadding 的对应边，默认 0。

    \qmlproperty int ComboBox::horizontalAlignment
    显示文本水平对齐，默认 \c Text.AlignHCenter。

    \qmlproperty int ComboBox::verticalAlignment
    显示文本垂直对齐，默认 \c Text.AlignVCenter。

    \qmlproperty int ComboBox::popupDirection
    弹出层方向。\c Qore.Covered（默认）：弹出层覆盖在控件上；
    \c Qore.Below：弹出层顶边紧贴控件底边；\c Qore.Above：弹出层底边
    紧贴控件顶边。

    \qmlproperty real ComboBox::popupOffsetX
    \qmlproperty real ComboBox::popupOffsetY
    弹出层相对默认位置的额外偏移（像素），默认 0。

    \qmlproperty QoolBoxSettings ComboBox::backgroundSettings
    背景外观设置（边框宽度/颜色、填充色、裁剪角），默认跟随
    \c Style 的控件外观（\c controlBorderWidth、\c controlBorderColor、
    \c controlBackgroundColor、\c controlCutSize）。

    \section1 信号文档

    \qmlsignal ComboBox::accepted()
    继承自 Qt 官方接口，在可编辑模式下编辑结束尝试被接受时发出（输入
    通过校验且与当前文本不一致），宿主在 \c onAccepted 中处理提交的
    编辑文本（见"可编辑模式"）。

    \qmlsignal ComboBox::rejected()
    Qool 扩展——编辑结束尝试被拒绝时发出（校验不通过；文本保持原值、
    model 不变），宿主可提示用户。

    \section1 可编辑模式（editable）
    \c editable 为 \c true 时，控件以 Qool TextField（双层强化版——展示层
    + 编辑会话）呈现文本，并支持文本选择（\c selectTextByMouse）等文本域
    能力；编辑域状态机由 TextField 承担（统一收尾/判定信号）。

    输入内容的处理路径：设置 \c validator 对输入校验——编辑结束尝试
    （Enter/失焦/Esc）时判定：输入可接受（\c acceptableInput）→ 发出
    \c accepted() 并结束编辑；不可接受 → 发出 \c rejected()（Qool 扩展）
    并结束编辑，文本保持原值（\b 契约差异：官方实现校验不通过时保持
    编辑状态——本类型统一结束并宣告拒绝）。\c accepted() 发出后
    \c editText 已同步为用户输入，宿主可在 \c onAccepted 中配合
    \c find() 匹配模型项、设置 \c currentIndex，或将新文本加入模型——
    注意 currentIndex/currentText 不会随提交自动更新，需宿主自行处理
    （编辑接受不改写 model 文本——显示以 currentText 为准，宿主处理后
    拉回；不处理则保留编辑文本）。popup 打开时按 Enter 激活高亮项，
    不经过编辑提交路径。

    \section1 flat 与委托
    \c flat 且未悬浮、弹出层未打开、文本域未聚焦时背景完全透明。
    delegate 默认使用 BasicItemDelegate，经 \c Style.follow 显式跟随
    控件样式；宿主可替换 \c delegate 自定义列表项外观。
*/

// 撤销编辑（Esc/校验失败）：由编辑域 TextField 的统一收尾承担——拒绝
// 判定（rejected）时文本保持原值（model 不变）——见 QDoc「可编辑模式」。

T.ComboBox {
    id: root

    property alias title: bgbox.title
    property alias label: bgbox.label

    property alias contentPadding: spacer.padding
    property alias contentTopPadding: spacer.topPadding
    property alias contentBottomPadding: spacer.bottomPadding
    property alias contentLeftPadding: spacer.leftPadding
    property alias contentRightPadding: spacer.rightPadding

    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter

    property int popupDirection: Qore.Covered
    property real popupOffsetX: 0
    property real popupOffsetY: 0

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.controlBorderColor
        fillColor: root.Style.controlBackgroundColor
        cutSizes: root.Style.buttonCutSize
        curved: true
    }

    /* Qool 扩展：编辑会话拒绝判定透传（TextField.rejected → 本信号）。
       编辑输入未通过校验时发出（文本保持原值——model 不变）——宿主可
       提示用户。官方 ComboBox 无此信号。 */
    signal rejected

    font.pixelSize: Style.controlTextSize

    SpaceHelper {
        id: spacer
    }

    background: QoolBGBox {
        id: bgbox
        settings: root.backgroundSettings
        implicitHeight: 35
        implicitWidth: 100
        // 编辑会话中（textField.editing——双层编辑域常驻，会话状态由
        // TextField 自管）背景不透明（编辑层浮于背景之上）
        opacity: (root.flat && !root.hovered && !root.popup.visible && !textField.editing) ? 0 : 1
        BasicNumberBehavior on opacity {}
    }

    topPadding: topInset + bgbox.topSpace + spacer.topPadding
    bottomPadding: bottomInset + bgbox.bottomSpace + spacer.bottomPadding
    leftPadding: leftInset + bgbox.leftSpace + spacer.leftPadding
    rightPadding: rightInset + bgbox.rightSpace + spacer.rightPadding

    implicitWidth: {
        let w1 = leftPadding + implicitContentWidth + rightPadding;
        let w2 = leftInset + implicitBackgroundWidth + rightInset;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        let h1 = topPadding + implicitContentHeight + bottomPadding;
        let h2 = topInset + implicitBackgroundHeight + bottomInset;
        return Math.max(h1, h2);
    }

    indicator: IndexIndicator {
        currentIndex: root.currentIndex
        model: root.model
        x: {
            if (root.mirrored)
                return root.contentItem.x;
            else
                return root.contentItem.x + root.contentItem.width - width;
        }

        y: root.contentItem.y
        height: root.contentItem.height
        BasicNumberBehavior on currentIndex {}
    }

    contentItem: Item {
        id: contentContainer
        implicitWidth: textField.implicitWidth
        implicitHeight: textField.implicitHeight
        readonly property real indicatorPadding: root.indicator.width + root.spacing

        // 编辑域：常驻 TextField（双层——展示层 + 编辑会话自管——编辑域
        // 状态机由 TextField 承担，本控件只做值映射与信号转发）。editable
        // 经 readOnly 控制（绑定）：非可编辑只读展示（点击穿透模板按钮
        // 行为开 popup）；可编辑点击进会话。显示文本以 model（currentText）
        // 为准——见下命令式同步。
        Q.TextField {
            id: textField
            anchors.fill: parent

            readOnly: !root.editable
            font: root.font
            color: root.Style.text
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment

            validator: root.validator
            inputMethodHints: root.inputMethodHints
            selectByMouse: root.selectTextByMouse

            leftPadding: root.mirrored ? contentContainer.indicatorPadding : 0
            rightPadding: root.mirrored ? 0 : contentContainer.indicatorPadding
        }

        // 命令式同步（用户裁定——不采用属性绑定：TextField 收尾内部写回
        // text 会打断外部属性绑定（QML 机制——任何赋值断绑定）且不可预期；
        // 命令式 Connections 同步显式、不受内部写回影响）。编辑接受后显示
        // 短暂为编辑文本——宿主处理模型（find/加入/强制 currentText）后
        // currentText 变化拉回；宿主不处理则保留编辑文本（官方 editText
        // 保留语义）。
        Connections {
            target: root
            function onCurrentTextChanged() {
                textField.text = root.currentText
            }
        }

        Connections {
            target: textField
            // editText 双向通道（官方属性）：text 变（收尾/模型同步）与
            // editText 变（编辑中输入）都同步到 root.editText——单向
            // （tf → root）：宿主读 editText 反映文本域实际内容；宿主写
            // editText 不反推（与现状一致——模板识别缺口下同款单向）
            function onTextChanged() {
                root.editText = textField.text
            }
            function onEditTextChanged() {
                root.editText = textField.editText
            }
            // 信号透传：accepted（官方语义保持——宿主在 onAccepted 中自行
            // find/editText 处理模型）；rejected（Qool 扩展——编辑输入被拒，
            // 文本保持原值）。收尾时 textField 先写 text 再发 accepted——
            // 上面 onTextChanged 先于本透传执行，宿主读 editText 已是收尾后值
            function onAccepted() {
                root.accepted()
            }
            function onRejected() {
                root.rejected()
            }
        }

        // 初始基准（Connections 不为属性初始值触发——此处补一次）
        Component.onCompleted: textField.text = root.currentText
    }

    delegate: BasicItemDelegate {
        required property var model
        required property int index
        // 自适应列表可视宽（官方写法）：popup 水平 padding 使可视区窄于
        // 控件宽——固定 root.width 会致右缘被裁 1-2px（修复 2026-08-10）
        width: ListView.view.width
        text: model[root.textRole]
        highlighted: root.highlightedIndex === index
        Style.follow: root.Style
    }

    popup: Popup {
        readonly property real implicitY: {
            switch (root.popupDirection) {
            case Qore.Below:
                return root.height - root.backgroundSettings.borderWidth;
            case Qore.Above:
                return 0 - height + root.backgroundSettings.borderWidth;
            }
            return 0;
        }
        x: 0 + root.popupOffsetX
        y: implicitY + root.popupOffsetY

        // 打开时显式收尾编辑会话（与 SpinBox 指示器收尾对称）：正常窗口化
        // 下 popup 抢焦点经失焦链收尾——此处显式化覆盖无焦点/程序化场景，
        // 避免会话跨 popup 存活（期间 TapHandler 禁用——点击内容区无法再进
        // 编辑）
        onVisibleChanged: if (visible && textField.editing)
                             textField.editing = false

        width: root.width
        height: Math.min(topPadding + implicitContentHeight + bottomPadding, root.Window.height - topMargin - bottomMargin)

        topPadding: 4
        bottomPadding: 4
        leftPadding: 1
        rightPadding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            Q.ScrollIndicator.vertical: Q.ScrollIndicator {}
        }

        background: QoolBox {
            settings: root.backgroundSettings
        }
    }

    containmentMask: background
    hoverEnabled: true

    ControlPressedCover {
        visible: root.pressed
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
    }

    ControlHighlightCover {
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        opacity: (root.enabled && root.hovered) ? 1 : 0
    }

    ControlLockedCover {
        color: root.Style.negative
    }
}
