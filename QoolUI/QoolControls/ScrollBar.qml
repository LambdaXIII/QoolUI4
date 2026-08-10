import QtQuick
import QtQuick.Templates as T
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

    minimumSize: 0.1

    TimerLatch {
        id: latch
        interval: 1750
        readonly property real visualOpacity: root.showIndicator ? 0.75 : 0
    }

    onScrollPositionChanged: latch.trigger()
    onVisualSizeChanged: latch.trigger()

    contentItem: Rectangle {
        id: indicator
        color: root.pressed ? root.Style.positive : root.Style.toolTipBase
        BasicColorBehavior on color {}

        opacity: (root.hovered || root.pressed || latch.active) ? 1 : latch.visualOpacity
        BasicNumberBehavior on opacity {
            duration: root.Style.movementDuration
        }

        radius: Math.floor(Math.min(width, height) / 2)
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    Binding {
        when: !root.horizontal
        indicator.implicitWidth: 8
        indicator.implicitHeight: 100
        root.leftPadding: 2
        root.rightPadding: 2
    }
    Binding {
        when: root.horizontal
        indicator.implicitWidth: 100
        indicator.implicitHeight: 8
        root.topPadding: 2
        root.bottomPadding: 2
    }
}
