import QtQuick
import Qool
import "_private"

Item {
    id: root

    property point point
    property string name

    property int infoPosition: Qore.RightTop
    property color color: "darkgreen"
    property real markerSize: 12
    property bool showMarker: true
    property bool showInfo: true
    property bool showName: true
    property real infoPadding: 4

    width: Math.max(10, markerSize + 2)
    height: width
    x: point.x - width / 2
    y: point.y - height / 2

    PopBox {
        id: marker
        visible: root.showMarker
        anchors.centerIn: parent
        size: root.markerSize
        color: root.color
    }

    PopInfo {
        id: infoPop
        visible: root.showInfo && root.showName
        contentItem: Row {
            PropertyTipText {
                displayValue: root.name
                valueColor: palette.toolTipText
                visible: root.showName
            }
            PropertyTipText {
                title: "x"
                titleColor: "orangered"
                displayValue: Qore.floatString(root.point.x, 1, true)
                visible: root.showInfo
            }
            PropertyTipText {
                title: "y"
                titleColor: "palegreen"
                displayValue: Qore.floatString(root.point.y, 1, true)
                visible: root.showInfo
            }
        }

        x: {
            if (Qore.positions.leftSide.includes(root.infoPosition))
                return 0 - root.infoPadding - infoPop.width;
            if (Qore.positions.rightSide.includes(root.infoPosition))
                return root.width + root.infoPadding;
            return (root.width - infoPop.width) / 2;
        }

        y: {
            if (Qore.positions.topSide.includes(root.infoPosition))
                return 0 - root.infoPadding - infoPop.height;
            if (Qore.positions.bottomSide.includes(root.infoPosition))
                return root.height + root.infoPadding;
            return (root.height - infoPop.height) / 2;
        }
    }
}
