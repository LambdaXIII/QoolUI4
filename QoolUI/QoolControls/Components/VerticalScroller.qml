import QtQuick
import QtQuick.Templates as T
import Qool

Item {
    id: root

    property T.Flickable target: parent
    property bool interactive: false
    property color color: Style.toolTipBase

    property Component indicator: Rectangle {
        color: root.color
        radius: Math.floow(root.width / 2)
        border.width: 0
    }

    implicitWidth: 4
    width: target.visibleArea.heightRatio >= 1.0 ? 0 : implicitWidth
    visible: width > 0

    x: parent.width - width
    height: parent.height

    Loader {
        id: indicatorLoader
        sourceComponent: root.indicator
        width: root.width
        height: target.visibleArea.heightRatio * root.height
        y: target.visibleArea.yPosition * root.height
        opacity: root.target.movingVertically || heightBehavior.running ? 1 : 0.2
        BasicNumberBehavior on opacity {
            duration: root.Style.movementDuration
        }
        BasicNumberBehavior on height {
            id: heightBehavior
        }
    }

    NumberAnimation {
        id: jumpAnimation
        target: root.target
        property: "contentY"
        easing.type: Easing.InOutQuad
        duration: root.Style.movementDuration
        onStarted: {
            if (!root.Style.animationEnabled)
                complete();
        }
    }

    MouseArea {
        id: topMouseArea
        width: Math.max(root.width, 20)
        height: Qore.bound(root.width, 20, root.height / 2)
        x: (root.width - width) / 2
        y: (root.width - height) / 2
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const target_y = 0;
            root.target.cancelFlick();
            jumpAnimation.stop();
            jumpAnimation.to = target_y;
            jumpAnimation.start();
        }
    }

    MouseArea {
        id: bottomMouseArea
        width: Math.max(root.width, 20)
        height: Qore.bound(root.width, 20, root.height / 2)
        x: (root.width - width) / 2
        y: (root.width - height) / 2 + (root.height - root.width)
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const target_y = root.target.contentHeight * (1
                                                          - root.target.visibleArea.heightRatio);
            root.target.cancelFlick();
            jumpAnimation.stop();
            jumpAnimation.to = target_y;
            jumpAnimation.start();
        }
    }

    MouseArea {
        id: middleMouseArea
        width: Math.max(root.width, 20)
        x: topMouseArea.x
        anchors {
            top: topMouseArea.bottom
            bottom: bottomMouseArea.top
        }
        cursorShape: Qt.CrossCursor
        onClicked: e => {
                       const root_point = mapToItem(root, e.x, e.y);
                       const real_y = root_point.y;
                       const ratio = real_y / root.height;
                       const target_y = root.target.contentHeight * Math.min(ratio, 1
                                                                             - root.target.visibleArea.heightRatio);
                       jumpAnimation.stop();
                       jumpAnimation.to = target_y;
                       jumpAnimation.start();
                   }
    }
}
