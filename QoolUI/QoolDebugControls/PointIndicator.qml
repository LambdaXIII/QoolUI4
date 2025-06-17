import QtQuick
import QtQuick.Controls.Basic
import Qool

Item {
    id: root
    property int textPosition: Qool.Right
    property real textSize: 12
    property color color: "darkgreen"
    property point point
    property string name
    property real indicatorSize: 12
    property bool showIndicator: true
    property bool showInfo: true

    width: Math.max(10, indicatorSize)
    height: width
    x: point.x - width / 2
    y: point.y - height / 2

    Popup {
        id: indicatorPop
        visible: root.showIndicator
        width: root.indicatorSize
        height: root.indicatorSize
        anchors.centerIn: root
        popupType: Popup.Item
        Rectangle {
            anchors.fill: parent
            radius: Math.min(4, root.indicatorSize / 2)
            border.color: root.color
            border.width: 2
            color: "transparent"
        }
        closePolicy: Popup.NoAutoClose
        background: Item {}
        padding: 0
        margins: 4
    }

    Popup {
        id: infoPop
        visible: root.showInfo
        popupType: Popup.Item
        closePolicy: Popup.NoAutoClose
        function shrink_n(x) {
            let a = Math.round(x * 100)
            return a / 100
        }

        readonly property string info: root.name + "(" + shrink_n(
                                           root.point.x) + "," + shrink_n(
                                           root.point.y) + ")"
        Text {
            text: infoPop.info
            font.pixelSize: root.textSize
            color: root.color
        }

        x: switch (root.textPosition) {
           case Qool.TopLeft:
           case Qool.Left:
           case Qool.BottomLeft:
               return indicatorPop.x - width
           case Qool.Top:
           case Qool.Center:
           case Qool.Bottom:
               return indicatorPop.x + (indicatorPop.width - width) / 2
           case Qool.TopRight:
           case Qool.Right:
           case Qool.BottomRight:
               return indicatorPop.x + indicatorPop.width
           default:
               return 0
           }

        y: switch (root.textPosition) {
           case Qool.TopLeft:
           case Qool.Top:
           case Qool.TopRight:
               return indicatorPop.y - height
           case Qool.Left:
           case Qool.Center:
           case Qool.Right:
               return indicatorPop.y + (indicatorPop.height - height) / 2
           case Qool.BottomLeft:
           case Qool.Bottom:
           case Qool.BottomRight:
               return indicatorPop.y + indicatorPop.height
           }
        background: Rectangle {
            color: "transparent"
            border.color: root.color
            radius: 6
            border.width: 1
        }
        padding: 6
    }
}
