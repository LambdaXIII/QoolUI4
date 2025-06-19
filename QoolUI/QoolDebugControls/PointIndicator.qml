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

    property int infoAnchorFrom: Qore.RightCenter
    property int infoAnchorTo: Qore.LeftCenter
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
        x: root.mapFromGlobal(posLinker.globalTargetPos).x
        y: root.mapFromGlobal(posLinker.globalTargetPos).y
    }

    Item {
        id: dummyInfoPop
        width: infoPop.implicitWidth
        height: infoPop.implicitHeight
    }

    PositionLinker {
        id: posLinker
        target: dummyInfoPop
        linkTo: root
        horizontalSpacing: 4
        verticalSpacing: 4
        targetAnchorPosition: root.infoAnchorTo
        linkToAnchorPosition: root.infoAnchorFrom
        autoLink: false
        Component.onCompleted: dumpInfo()
    }
}
