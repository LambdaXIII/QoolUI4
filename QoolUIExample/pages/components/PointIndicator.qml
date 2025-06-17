import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    property point position: Qt.point(0, 0)
    property color color: "#2b2b2b"
    property string name
    property real textSize: 12

    enum TextPos {
        Left,
        Right,
        Top,
        Bottom
    }
    property int textPos: PointIndicator.Top

    width: 10
    height: 10
    x: position.x - width / 2
    y: position.y - height / 2

    QtObject {
        id: pCtrl
        function check_number(num) {
            let a = Math.round(num * 100)
            return a / 100
        }

        readonly property string posText: root.name + "(" + check_number(
                                              root.position.x) + ", " + check_number(
                                              root.position.y) + ")"
    }

    Rectangle {
        id: indicator
        width: 8
        height: 8
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: root.color
        anchors.centerIn: parent
    }

    Text {
        id: tt
        text: pCtrl.posText
        color: root.color
        x: {
            if (root.textPos === PointIndicator.Left)
                return 0 - width
            if (root.textPos === PointIndicator.Right)
                return root.width
            return (root.width - width) / 2
        }

        y: {
            if (root.textPos === PointIndicator.Top)
                return 0 - height
            if (root.textPos === PointIndicator.Bottom)
                return root.height
            return (root.height - height) / 2
        }
    } //Text
}
