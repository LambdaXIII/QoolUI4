import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls.Components
import Qool.Controls as Q
import Qool

/*!
    \qmltype QoolComboBox
    \inqmlmodule Qool.Controls
    \brief 基于 T.ComboBox 的 QoolUI 风格下拉选择框，contentItem 直连 BasicTextField。

    与 ComboBox 的差异在于结构：BasicTextField 直接内联为 contentItem，
    无 sourceComponent 组件边界，因此其 id（textField）在根作用域可直接
    引用——背景透明判断直接使用 textField.activeFocus，无需经 Loader
    间接空安全访问。\c backgroundSettings 为 \c bgbox.settings 的别名
    （注意与 ComboBox 的实例值绑定不同，此处直接别名，改动同步生效）。
    \c title/\c label 与 \c contentPadding 系列同 ComboBox 一致。

    \section2 delegate 必须显式 Style.follow
    popup 渲染在 Overlay 层，attached 属性传播链在 Overlay 处断掉，
    delegate 收不到 root.Style 的自动跟随；若不显式
    \c Style.follow: \c root.Style，delegate 样式会回退到默认主题，
    与控件主体样式不一致。
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

    property alias backgroundSettings: bgbox.settings

    backgroundSettings {
        borderWidth: Style.controlBorderWidth
        borderColor: Style.controlBorderColor
        fillColor: Style.controlBackgroundColor
        cutSizeTL: Style.controlCutSize
    }

    font.pixelSize: Style.controlTextSize

    SpaceHelper {
        id: spacer
    }

    background: QoolBGBox {
        id: bgbox
        implicitHeight: 35
        implicitWidth: 100
        opacity: (root.flat && !root.hovered && !root.popup.visible &&
                  !textField.activeFocus) ? 0 : 1
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
                return root.leftPadding;
            else
                return root.width - width - root.rightPadding;
        }

        y: root.topPadding
        height: root.height - root.topPadding - root.bottomPadding
        BasicNumberBehavior on currentIndex {}
    }

    contentItem: BasicTextField {
        id: textField
        readonly property real indicatorPadding: root.indicator.width + root.spacing
        leftPadding: root.mirrored ? indicatorPadding : 0
        rightPadding: root.mirrored ? 0 : indicatorPadding
        topPadding: 6 - root.padding
        bottomPadding: 6 - root.padding

        text: root.editable ? root.editText : root.displayText
        font: root.font

        enabled: root.editable
        autoScroll: root.editable
        readOnly: root.down
        inputMethodHints: root.inputMethodHints
        validator: root.validator
        selectByMouse: root.selectTextByMouse

        color: root.editable ? root.Style.text : root.Style.buttonText

        horizontalAlignment: Text.AlignHCenter
    }

    delegate: BasicItemDelegate {
        required property var model
        required property int index
        width: root.width
        text: model[root.textRole]
        highlighted: root.highlightedIndex === index
        // popup 渲染在 Overlay 层，attached 属性传播链在此断掉——delegate
        // 收不到 root.Style 的自动跟随，必须显式 follow（否则 delegate 样式
        // 回退到默认主题，与控件主体样式不一致）。
        Style.follow: root.Style
    }

    popup: Popup {
        y: root.height - 1
        width: root.width
        height: Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
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

        background: Rectangle {
            border.width: root.backgroundSettings.borderWidth
            border.color: root.backgroundSettings.borderColor
            color: root.backgroundSettings.fillColor
        }
    }

    containmentMask: background
    hoverEnabled: true

    ControlPressedCover {
        visible: root.pressed
        highColor: Style.highlight
        lowColor: Style.highlightedText
    }

    ControlHighlightCover {
        highColor: Style.highlight
        lowColor: Style.highlightedText
        opacity: (root.enabled && root.hovered) ? 1 : 0
    }

    ControlLockedCover {
        color: Style.negative
    }
}
