import QtQuick
// import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Controls as QControls
import Qool

T.ScrollBar {
    id: root

    readonly property bool showIndicator: {
        if (root.policy == ScrollBar.AlwaysOn)
            return true
        return root.active && root.size < 1.0
    }

    readonly property real scrollPosition: {
        return Qore.remap(root.position, 0, 1 - root.size)
    }

    contentItem: Rectangle {
        id: indicator
        color: root.pressed ? root.Style.positive : root.Style.toolTipBase
        BasicColorBehavior on color {}

        opacity: root.pressed ? 1 : (root.showIndicator ? 0.8 : 0)
        BasicNumberBehavior on opacity {
            duration: root.Style.movementDuration
        }

        radius: Math.floor(Math.min(width, height) / 2)

        Binding {
            when: !root.horizontal
            indicator.implicitWidth: 8
            indicator.implicitHeight: 100
        }
        Binding {
            when: root.horizontal
            indicator.implicitWidth: 100
            indicator.implicitHeight: 8
        }

        Floater {
            content: BasicLabel {
                text: Qore.floatString(root.scrollPosition * 100, 2, true) + "%"
                color: indicator.color
            }

            opacity: (root.hovered || root.pressed) ? indicator.opacity : 0
            x: 0 - width - 6
            y: parent.height * root.scrollPosition - height / 2
        }
    }

    background: Item {
        implicitWidth: 5
        implicitHeight: 5
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding
}
