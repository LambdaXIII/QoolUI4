import QtQuick
import Qool
import "_private"

Item {
    id: root

    property point point
    property string name

    property color color: "darkgreen"
    property real markerSize: 12
    property bool showMarker: true
    property bool showInfo: true
    property bool showName: true
    property real infoPadding: 4

    property int infoAnchorFrom: Qore.BottomLeft
    property int infoAnchorTo: Qore.TopLeft
    property int infoPosition: Qore.Center

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
        x: dummyInfoPop.x
        y: dummyInfoPop.y
    }

    Item {
        id: dummyInfoPop
        visible: false
        width: infoPop.implicitWidth
        height: infoPop.implicitHeight
    }

    ItemRelativePositioner {
        id: linker
        item: dummyInfoPop
        relativeFrom: root
        horizontalSpacing: 4
        verticalSpacing: 4
        fromAnchorPosition: root.infoAnchorFrom
        toAnchorPosition: root.infoAnchorTo
    }

    Component.onCompleted: {
        linker.dumpInfo()
    }
}
