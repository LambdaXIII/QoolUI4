import QtQuick
import QtQuick.Templates as T
import Qool

T.Control {
    id: root

    property alias title: bgbox.title
    property alias label: bgbox.label

    property alias contentPadding: spacer.padding
    property alias contentTopPadding: spacer.topPadding
    property alias contentBottomPadding: spacer.bottomPadding
    property alias contentLeftPadding: spacer.leftPadding
    property alias contentRightPadding: spacer.rightPadding

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.controlCutSize
        borderWidth: root.Style.controlBorderWidth
        borderColor: root.Style.controlBorderColor
        fillColor: root.Style.controlBackgroundColor
    }

    background: QoolBGBox {
        id: bgbox
        settings: root.backgroundSettings
    }

    SpaceHelper {
        id: spacer
        leftPadding: 2
        rightPadding: 2
    }

    topPadding: topInset + bgbox.topSpace + spacer.topPadding
    bottomPadding: bottomInset + bgbox.bottomSpace + spacer.bottomPadding
    leftPadding: leftInset + bgbox.leftSpace + spacer.leftPadding
    rightPadding: rightInset + bgbox.rightSpace + spacer.rightPadding

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

    containmentMask: background
}
