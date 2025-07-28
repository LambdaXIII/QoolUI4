import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import Qool.Controls.Components
import Qool.Controls as Q
import Qool

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
