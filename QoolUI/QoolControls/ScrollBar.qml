import QtQuick
// import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Controls as QControls
import Qool

T.ScrollBar {
    id: root

    readonly property bool showIndicator: {
        if (root.policy == ScrollBar.AlwaysOn)
            return true;
        return root.active && root.size < 1.0;
    }

    readonly property real scrollPosition: {
        return Qore.remap(root.position, 0, 1 - root.size);
    }

    QtObject {
        id: pCtrl
        readonly property real visualOpacity: 0.75
    }

    contentItem: Rectangle {
        id: indicator
        color: root.pressed ? root.Style.positive : root.Style.toolTipBase
        BasicColorBehavior on color {}

        opacity: root.pressed ? 1 : (root.showIndicator ? pCtrl.visualOpacity : 0)
        BasicNumberBehavior on opacity {
            duration: root.Style.movementDuration
        }

        radius: Math.floor(Math.min(width, height) / 2)

        Floater {
            id: floater
            content: BasicLabel {
                text: Qore.floatString(root.scrollPosition * 100, 2, true) + "%"
                color: indicator.color
            }
            opacity: {
                if (root.hovered || root.pressed)
                    return pCtrl.visualOpacity;
                if (root.size > 0.5)
                    return 0;
                if (root.policy === ScrollBar.AlwaysOn)
                    return 0;
                return pCtrl.visualOpacity;
            }
            BasicNumberBehavior on opacity {
                duration: root.Style.movementDuration
            }
        }
    }

    background: Item {
        implicitWidth: 5
        implicitHeight: 5
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    Binding {
        when: !root.horizontal
        indicator.implicitWidth: 8
        indicator.implicitHeight: 100
        floater.x: 0 - floater.width - 6
        floater.y: indicator.height * root.scrollPosition - floater.height / 2
    }
    Binding {
        when: root.horizontal
        indicator.implicitWidth: 100
        indicator.implicitHeight: 8
        floater.x: indicator.width * root.scrollPosition - floater.width / 2
        floater.y: indicator.height + floater.height + 6
    }
}
