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
    继承自 Qt 官方接口，在可编辑模式下按 Enter 提交时发出，宿主在
    \c onAccepted 中处理提交的编辑文本（见"可编辑模式"）。

    \section1 可编辑模式（editable）
    \c editable 为 \c true 时，控件以 BasicTextField 呈现文本（编辑与
    非编辑态皆由它承担），并支持文本选择（\c selectTextByMouse）等
    文本域能力。

    输入内容的处理路径：设置 \c validator 对输入校验——仅当输入处于
    可接受状态（\c acceptableInput）时按 Enter 才会发出 \c accepted()
    并提交，校验不通过则保持编辑状态。\c accepted() 发出后 \c editText
    已同步为用户输入，宿主可在 \c onAccepted 中配合 \c find() 匹配
    模型项、设置 \c currentIndex，或将新文本加入模型——注意
    currentIndex/currentText 不会随提交自动更新，需宿主自行处理。
    提交后焦点自动释放，编辑立即结束，无需外部焦点对象。popup 打开
    时按 Enter 激活高亮项，不经过编辑提交路径。

    \section1 flat 与委托
    \c flat 且未悬浮、弹出层未打开、文本域未聚焦时背景完全透明。
    delegate 默认使用 BasicItemDelegate，经 \c Style.follow 显式跟随
    控件样式；宿主可替换 \c delegate 自定义列表项外观。
*/

//TODO: 需要梳理撤销编辑行为具体如何实现。可能改为TextField临时出现？但这样涉及大量相关逻辑重做，与QtQuick默认设计有区别.

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

    font.pixelSize: Style.controlTextSize

    SpaceHelper {
        id: spacer
    }

    background: QoolBGBox {
        id: bgbox
        settings: root.backgroundSettings
        implicitHeight: 35
        implicitWidth: 100
        // 注意：不能给 sourceComponent 内的 BasicTextField 加 id 后直接引用
        // （内联 sourceComponent 是组件边界，内部 id 对外不可见，会
        // ReferenceError）。经 textFieldLoader.item 可空访问 activeFocus，
        // 未加载（非 editable）时为 undefined。
        opacity: (root.flat && !root.hovered && !root.popup.visible && !textFieldLoader.item?.activeFocus) ? 0 : 1
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
        implicitWidth: simpleText.implicitWidth
        implicitHeight: simpleText.implicitHeight
        readonly property real indicatorPadding: root.indicator.width + root.spacing
        Text {
            id: simpleText
            text: root.displayText
            font: root.font
            enabled: root.enabled
            color: root.Style.buttonText
            horizontalAlignment: root.horizontalAlignment
            verticalAlignment: root.verticalAlignment
            anchors.fill: parent

            leftPadding: root.mirrored ? contentContainer.indicatorPadding : 0
            rightPadding: root.mirrored ? 0 : contentContainer.indicatorPadding
            visible: !root.editable
            BasicTextBehavior on text {}
        }
        Loader {
            id: textFieldLoader
            anchors.fill: parent
            active: root.editable
            sourceComponent: BasicTextField {
                text: root.editable ? root.editText : root.displayText
                font: root.font

                enabled: root.enabled && root.editable
                autoScroll: root.editable
                readOnly: root.down
                inputMethodHints: root.inputMethodHints
                validator: root.validator
                selectByMouse: root.selectTextByMouse

                color: root.editable ? root.Style.text : root.Style.buttonText

                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment

                readonly property real extraPadding: activeFocus ? 10 : 0
                leftPadding: root.mirrored ? contentContainer.indicatorPadding + extraPadding : 0
                rightPadding: root.mirrored ? 0 : contentContainer.indicatorPadding + extraPadding

                // 模板层按 contentItem 类型识别文本域，Loader 包裹下识别
                // 不到：editText 不随输入自动同步（须手动回写）。Enter 的
                // accepted 是文本域自身信号——先经 root.accepted() 激活
                // ComboBox 的 accepted 信号（宿主 onAccepted 入口，与 Qt
                // 官方语义一致：宿主在 onAccepted 中经 find(editText) 处理
                // 输出数值；Qt 内部的模型匹配/currentIndex 更新不随此调用
                // 执行，由宿主自行处理），再释放焦点结束编辑，避免外部
                // 无焦点对象时编辑状态悬挂。
                //一些互动行为&反向同步属性
                onTextEdited: root.editText = text

                onAccepted: {
                    root.accepted();
                    focus = false;
                }
            }
        }
    }

    delegate: BasicItemDelegate {
        required property var model
        required property int index
        width: root.width
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
