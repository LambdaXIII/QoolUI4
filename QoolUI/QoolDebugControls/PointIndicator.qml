import QtQuick
import Qool
import "_private"

Item {
    id: root

    property point point
    property string name

    property int textPosition: Qool.Right
    property real textSize: 12
    property color color: "darkgreen"
    property real markerSize: 12
    property bool showMarker: true
    property bool showInfo: true
    property bool showName: true

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
        visible: root.showInfo
        contentItem: Row {
            PropertyTipText {
                title: "x"
                titleColor: "red"
                displayValue: Qool.format_float(root.point.x, 3)
            }
            PropertyTipText {
                title: "y"
                titleColor: "green"
                displayValue: Qool.format_float(root.point.y, 3)
            }
        }
    }

    PopInfo {
        id: namePop
        visible: root.showName
        contentItem: Text {
            text: root.name
            font.pixelSize: 10
            color: palette.accent
        }
    }
}
