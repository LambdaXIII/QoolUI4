import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls.Components
import Qool.Controls as Q
import Qool

/*!
    \qmltype ComboBox
    \inqmlmodule Qool.Controls
    \brief 基于 T.ComboBox 的 QoolUI 风格下拉选择框，支持可编辑文本与可配置的弹出方向。

    外观由 \c backgroundSettings（QoolBoxSettings）与内嵌 QoolBGBox 统一提供；
    \c title/\c label 透传至背景盒，\c contentPadding 系列（含
    \c contentTop/Bottom/Left/RightPadding）经 SpaceHelper 控制内容内边距；
    \c horizontalAlignment/\c verticalAlignment 决定显示文本的对齐方式。

    \section2 可编辑模式（editable）
    非可编辑时显示普通文本（simpleText）；\c editable 为 \c true 时经
    \c textFieldLoader 按需加载 BasicTextField。加载器使用内联
    sourceComponent，构成组件边界——内部 id 对外不可见，因此焦点判断
    必须经 \c textFieldLoader.item?.activeFocus 空安全访问（未加载时为
    undefined）；QoolComboBox 因 contentItem 直接内联 BasicTextField、
    无组件边界，可直接引用其 id。

    \section2 弹出方向（popupDirection）
    \c Qore.Covered（默认）时弹出层覆盖在控件上；\c Qore.Below 时弹出层
    顶边紧贴控件底边（扣除边框宽度），\c Qore.Above 时弹出层底边紧贴
    控件顶边。\c popupOffsetX/\c popupOffsetY 提供额外像素偏移。

    \section2 flat 与委托
    \c flat 且未悬浮、弹出层未打开、文本域未聚焦时背景完全透明。
    delegate 使用 BasicItemDelegate，经 \c Style.follow 显式跟随控件样式。
*/

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
        // ReferenceError——QoolComboBox 能直接引用是因为其 contentItem
        // 直接内联 BasicTextField，无组件边界）。经 textFieldLoader.item
        // 可空访问 activeFocus，未加载（非 editable）时为 undefined。
        opacity: (root.flat && !root.hovered && !root.popup.visible &&
                  !textFieldLoader.item?.activeFocus) ? 0 : 1
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
                leftPadding: root.mirrored ? contentContainer.indicatorPadding
                                             + extraPadding : 0
                rightPadding: root.mirrored ? 0 : contentContainer.indicatorPadding
                                              + extraPadding
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
        height: Math.min(topPadding + implicitContentHeight + bottomPadding,
                         root.Window.height - topMargin - bottomMargin)

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
