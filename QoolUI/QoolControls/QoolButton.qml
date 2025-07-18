import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components

T.AbstractButton {
    id: root

    property alias title: bgbox.title
    property alias label: bgbox.label

    property bool flat: false
    property bool highlight: hovered

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

    background: QoolBGBox {
        id: bgbox
    }

    SpaceHelper {
        id: spacer
    }

    topPadding: topInset + bgbox.topSpace + spacer.topPadding
    bottomPadding: bottomInset + bgbox.bottomSpace + spacer.bottomPadding
    leftPadding: leftInset + spacer.leftPadding
    rightPadding: rightInset + spacer.rightPadding

    font.pixelSize: Style.textSize

    contentItem: BasicButtonText {
        text: root.text
        font: root.font
        horizontalAlignment: Text.AlignRight
        BasicTextBehavior on text {}
    }

    ControlPressedCover {
        visible: root.down
        highColor: Style.highlight
        lowColor: Style.highlightedText
    }

    ControlHighlightCover {
        highColor: Style.highlight
        lowColor: Style.highlightedText
        opacity: root.highlighted || root.hovered ? 1 : 0
    }

    ControlLockedCover {
        color: Style.negative
    }

    SmartObject {
        id: pCtrl
        property real frameOpacity: root.flat ? 0 : 1

        BasicNumberBehavior on frameOpacity {
            enabled: root.Style.animationEnabled
        }

        Binding {
            when: !(root.checked || root.hovered || root.down)
                  && pCtrl.frameOpacity < 1
            target: root.background
            property: "opacity"
            value: pCtrl.frameOpacity
        }
    }

    implicitWidth: {
        const w1 = leftInset + implicitBackgroundWidth + rightInset
        const w2 = leftPadding + implicitContentWidth + rightPadding
        return Math.max(w1, w2)
    }

    implicitHeight: {
        const h1 = topInset + implicitBackgroundHeight + bottomInset
        const h2 = topPadding + implicitContentHeight + bottomPadding
        return Math.max(h1, h2)
    }

    Binding {
        when: root.checkable && root.checked
        target: bgbox.settings
        property: "borderColor"
        value: root.Style.highlight
    }
}
