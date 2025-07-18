import QtQuick
import QtQuick.Templates as T
import Qool

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
    property alias backgroundFillItem: bgbox.fillItem

    background: QoolBGBox {
        id: bgbox
        settings: root.backgroundSettings
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
}
