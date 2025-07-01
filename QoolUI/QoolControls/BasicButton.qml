import QtQuick
import Qool
import Qool.Controls.Components

BasicButtonFrame {
    id: root

    property bool animationEnabled: parent?.animationEnabled
                                    ?? Qore.animationEnabled

    property bool flat: false
    property bool highlighted: hovered

    property color highlightColor: palette.highlight
    property color highlightedTextColor: palette.highlightedText
    property color disabledColor: Qore.style.negative

    hoverEnabled: true

    font.pixelSize: Qore.style.controlTextSize

    contentItem: BasicButtonText {
        text: root.text
        font: root.font
        //TODO:support QtQuick icon behaviors
    }

    ControlPressedCover {
        visible: root.down
        highColor: root.highlightColor
        lowColor: root.highlightedTextColor
    }

    ControlHighlightCover {
        opacity: root.highlighted ? 1 : 0
    }

    ControlLockedCover {
        color: disabledColor
    }

    SmartObject {
        id: pCtrl
        property real frameOpacity: root.flat ? 0 : 1
        BasicNumberBehavior on frameOpacity {
            enabled: root.animationEnabled
        }

        Binding {
            when: pCtrl.frameOpacity < 1
            target: root.titleLoader
            property: "opacity"
            value: pCtrl.frameOpacity
        }

        Binding {
            when: pCtrl.frameOpacity < 1
            target: root.background
            property: "opacity"
            value: pCtrl.frameOpacity
        }
    }
}
