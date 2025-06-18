import QtQuick
import Qool
import "_private"

Item {
    id: root

    property point point
    property string name

    property int infoPosition: Qool.RightTop
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
                displayValue: Qool.format_float(root.point.x, 1, true)
                visible: root.showInfo
            }
            PropertyTipText {
                title: "y"
                titleColor: "palegreen"
                displayValue: Qool.format_float(root.point.y, 1, true)
                visible: root.showInfo
            }
        }

        x: {
            if (Qool.positionsOnLeftSide.includes(root.infoPosition))
                return 0 - root.infoPadding - infoPop.width;
            if (Qool.positionsOnRightSide.includes(root.infoPosition))
                return root.width + root.infoPadding;
            return (root.width - infoPop.width) / 2;
        }

        y: {
            if (Qool.positionsOnTopSide.includes(root.infoPosition))
                return 0 - root.infoPadding - infoPop.height;
            if (Qool.positionsOnBottomSide.includes(root.infoPosition))
                return root.height + root.infoPadding;
            return (root.height - infoPop.height) / 2;
        }
    }
}
