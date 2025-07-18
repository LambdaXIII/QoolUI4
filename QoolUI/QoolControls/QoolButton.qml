import QtQuick
import QtQuick.Templates as T
import Qool.Controls.Components

BasicButton {
    id: root

    ControlPressedCover {
        visible: root.down
        highColor: Style.highlight
        lowColor: Style.highlightedText
    }

    ControlHighlightCover {
        highColor: Style.highlight
        lowColor: Style.highlightedText
        opacity: root.highlighted || (root.enabled && root.hovered) ? 1 : 0
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

    Binding {
        when: root.checkable && root.checked
        target: root.backgroundSettings
        property: "borderColor"
        value: root.Style.highlight
    }

    // Binding {
    //     when: !root.enabled
    //     target: root.backgroundSettings
    //     property: "borderColor"
    //     value: root.Style.negative
    // }
}
