import QtQuick
import Qool
import Qool.Controls.Components

BasicButtonFrame {
    id: root



    property bool flat: false
    property bool highlighted: hovered

    property color highlightColor: Style.highlight
    property color highlightedTextColor: Style.highlightedText
    property color disabledColor: Style.negative

    hoverEnabled: true

    font.pixelSize: Style.controlTextSize

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
        highColor: root.highlightColor
        lowColor: root.highlightedTextColor
        opacity: root.highlighted ? 1 : 0
    }

    ControlLockedCover {
        color: disabledColor
    }

    SmartObject {
        id: pCtrl
        property real frameOpacity: root.flat ? 0 : 1

        BasicNumberBehavior on frameOpacity {
            enabled: root.Style.animationEnabled
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

    // BasicColorBehavior on backgroundColor {}
    // BasicColorBehavior on borderColor {}
    // BasicColorBehavior on highlightColor {}
    // BasicColorBehavior on highlightedTextColor {}
    // BasicColorBehavior on disabledColor {}
}
