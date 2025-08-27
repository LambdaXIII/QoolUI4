import QtQuick
import Qool

Item {
    id: root

    property color color: Style.toolTipBase
    property real spacing: 20
    property real handleWidth: 10

    anchors.fill: parent

    Floater {
        id: rightFloater
        content: DragMoveArea {
            width: rightFloater.width
            height: rightFloater.height
            cursorShape: Qt.SizeHorCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, _) => {
                             root.parent.width += x
                         }
        }
        width: root.handleWidth
        height: root.height
        x: root.width + root.spacing
    }

    Floater {
        id: leftFloater
        content: DragMoveArea {
            width: leftFloater.width
            height: leftFloater.height
            cursorShape: Qt.SizeHorCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, _) => {
                             root.parent.x += x
                             root.parent.width -= x
                         }
        }
        width: root.handleWidth
        height: root.height
        x: 0 - root.spacing - width
    }

    Floater {
        id: topFloater
        content: DragMoveArea {
            width: topFloater.width
            height: topFloater.height
            cursorShape: Qt.SizeVerCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (_, y) => {
                             root.parent.y += y
                             root.parent.height -= y
                         }
        }
        width: root.width
        height: root.handleWidth
        y: 0 - root.spacing - height
    }

    Floater {
        id: bottomFloater
        content: DragMoveArea {
            width: bottomFloater.width
            height: bottomFloater.height
            cursorShape: Qt.SizeVerCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (_, y) => {
                             root.parent.height += y
                         }
        }
        width: root.width
        height: root.handleWidth
        y: root.height + root.spacing
    }

    Floater {
        id: topLeftFloater
        content: DragMoveArea {
            width: topLeftFloater.width
            height: topLeftFloater.height
            cursorShape: Qt.SizeAllCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
                radius: width / 2
            }
            onWannaMove: (x, y) => {
                             root.parent.x += x
                             root.parent.y += y
                         }
        }
        width: root.handleWidth * 1.5
        height: root.handleWidth * 1.5
        x: 0 - root.spacing - width
        y: 0 - root.spacing - height
    }

    Floater {
        id: bottomRightFloater
        content: DragMoveArea {
            width: bottomRightFloater.width
            height: bottomRightFloater.height
            cursorShape: Qt.SizeFDiagCursor
            Rectangle {
                anchors.fill: parent
                color: root.color
                opacity: parent.pressed ? 1 : 0.2
            }
            onWannaMove: (x, y) => {
                             root.parent.width += x
                             root.parent.height += y
                         }
        }
        width: root.handleWidth
        height: root.handleWidth
        x: root.width + root.spacing
        y: root.height + root.spacing
    }
}
