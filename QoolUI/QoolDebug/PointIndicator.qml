import QtQuick
import QtQuick.Controls
import Qool
import "_private"

Floater {
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

    width: Math.max(10, markerSize + 2)
    height: width
    x: point.x - markerSize / 2
    y: point.y - markerSize / 2

    floatingItem: Item {
        implicitWidth: root.markerSize
        implicitHeight: root.markerSize
        Rectangle {
            id: marker
            color: "transparent"
            border.color: root.color
            border.width: 1
            width: root.markerSize
            height: root.markerSize
            visible: root.showMarker
        }
        Control {
            id: infoControl
            contentItem: Row {
                PropertyTipText {
                    displayValue: root.name
                    valueColor: root.color
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
            } //contentItem
            background: Rectangle {
                implicitHeight: 10
                implicitWidth: 10
                color: Qt.alpha(Style.mid, 0.8)
                radius: 4
                border.width: 1
                border.color: Qt.alpha(root.color, 0.35)
            }
            padding: 2
        } //infoControl
        PositionLocker {
            target: infoControl
            lockTo: marker
            targetAnchorPosition: root.infoAnchorTo
            lockToAnchorPosition: root.infoAnchorFrom
            horizontalSpacing: 4
            verticalSpacing: 4
        }
    } //floatingItem
}
