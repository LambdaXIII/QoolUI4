import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components
import Qool

T.AbstractButton {
    id: root

    property QoolBoxSettings backgroundSettings: QoolBoxSettings {
        cutSizes: root.Style.buttonCutSize
        fillColor: root.Style.button
        borderColor: root.Style.controlBorderColor
        borderWidth: root.Style.controlBorderWidth
        curved: true
    }

    property bool highlighted: enabled && hovered
    property bool flat: false

    font.pixelSize: root.Style.controlTextSize
    hoverEnabled: true

    SmartObject {
        id: pCtrl
        property real topSpace: Math.max(root.backgroundSettings.cutSizeTL,
                                         root.backgroundSettings.cutSizeTR)
        property real bottomSpace: Math.max(root.backgroundSettings.cutSizeBL,
                                            root.backgroundSettings.cutSizeBR)
        property real leftSpace: Math.max(root.backgroundSettings.cutSizeTL,
                                          root.backgroundSettings.cutSizeBL)
        property real rightSpace: Math.max(root.backgroundSettings.cutSizeTR,
                                           root.backgroundSettings.cutSizeBR)

        property real frameOpacity: root.flat ? 0 : 1

        BasicNumberBehavior on frameOpacity {
            enabled: root.Style.animationEnabled
        }

        Binding {
            when: pCtrl.frameOpacity < 1
            target: root.background
            property: "opacity"
            value: pCtrl.frameOpacity
        }
    }

    contentItem: BasicButtonText {
        id: mainText
        text: root.text
        font: root.font
        color: root.checked ? root.Style.highlightedText : root.Style.buttonText
    }

    leftPadding: root.backgroundSettings.borderWidth + pCtrl.leftSpace / 2
    rightPadding: root.backgroundSettings.borderWidth + pCtrl.rightSpace / 2
    topPadding: root.backgroundSettings.borderWidth + pCtrl.topSpace / 2
    bottomPadding: root.backgroundSettings.borderWidth + pCtrl.bottomSpace / 2

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    background: Rectangle {
        id: bgBox
        topLeftRadius: root.backgroundSettings.cutSizeTL
        topRightRadius: root.backgroundSettings.cutSizeTR
        bottomLeftRadius: root.backgroundSettings.cutSizeBL
        bottomRightRadius: root.backgroundSettings.cutSizeBR
        color: root.checked ? root.Style.highlight : root.backgroundSettings.fillColor
        border.width: root.backgroundSettings.borderWidth
        border.color: root.checked ? root.Style.highlightedText : root.backgroundSettings.borderColor
    }

    ControlPressedCover {
        visible: root.down
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        settings: root.backgroundSettings
    }

    ControlHighlightCover {
        highColor: root.Style.highlight
        lowColor: root.Style.highlightedText
        opacity: root.highlighted ? 1 : 0
        settings: root.backgroundSettings
    }

    ControlLockedCover {
        color: root.Style.negative
        settings: root.backgroundSettings
    }
}
