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
        opacity: (root.flat && !root.hovered && !root.popup.visible
                  && !textField.activeFocus) ? 0 : 1
        BasicNumberBehavior on opacity {}
    }

    topPadding: topInset + bgbox.topSpace + spacer.topPadding
    bottomPadding: bottomInset + bgbox.bottomSpace + spacer.bottomPadding
    leftPadding: leftInset + bgbox.leftSpace + spacer.leftPadding
    rightPadding: rightInset + bgbox.rightSpace + spacer.rightPadding

    implicitWidth: {
        let w1 = leftPadding + implicitContentWidth + rightPadding
        let w2 = leftInset + implicitBackgroundWidth + rightInset
        return Math.max(w1, w2)
    }
    implicitHeight: {
        let h1 = topPadding + implicitContentHeight + bottomPadding
        let h2 = topInset + implicitBackgroundHeight + bottomInset
        return Math.max(h1, h2)
    }

    indicator: IndexIndicator {
        currentIndex: root.currentIndex
        model: root.model
        x: {
            if (root.mirrored)
                return root.contentItem.x
            else
                return root.contentItem.x + root.contentItem.width - width
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
            }
        }
    }

    delegate: BasicItemDelegate {
        required property var model
        required property int index
        width: root.width
        text: model[root.textRole]
        highlighted: root.highlightedIndex === index
    }

    popup: Popup {
        readonly property real implicitY: {
            switch (root.popupDirection) {
            case Qore.Below:
                return root.height - root.backgroundSettings.borderWidth
            case Qore.Above:
                return 0 - height + root.backgroundSettings.borderWidth
            }
            return 0
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
