import QtQuick
import QtQuick.Templates as T
import Qool

T.ScrollIndicator {
    id: root

    property color color: Style.highlight

    property bool alwaysOn: true

    readonly property bool showIndicator: {
        if (root.size === 1)
            return false;
        if (root.alwaysOn)
            return true;
        return root.active && root.size < 1.0;
    }

    readonly property real scrollPosition: {
        return Qore.remap(root.position, 0, 1 - root.size);
    }

    minimumSize: 0.1

    DelayTimer {
        id: delayer
        readonly property real visualOpacity: root.showIndicator ? 0.25 : 0
        onStarted: indicator.opacity = 1
        onFinished: indicator.opacity = visualOpacity
        interval: 1750
    }

    onScrollPositionChanged: delayer.restart()
    onVisualSizeChanged: delayer.restart()

    contentItem: Rectangle {
        id: indicator
        color: root.color
        radius: Math.floor(Math.min(width, height))
        opacity: delayer.visualOpacity
        BasicNumberBehavior on opacity {}
    }

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    Binding {
        when: !root.horizontal
        indicator.implicitWidth: 4
        indicator.implicitHeight: 100
        root.leftPadding: 2
        root.rightPadding: 2
    }
    Binding {
        when: root.horizontal
        indicator.implicitWidth: 100
        indicator.implicitHeight: 4
        root.topPadding: 2
        root.bottomPadding: 2
    }
}
