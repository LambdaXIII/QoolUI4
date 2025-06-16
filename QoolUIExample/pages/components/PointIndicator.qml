import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    property point position: Qt.point(0, 0)
    property color color: "red"
    property color textColor: "black"
    property string name
    property real textSize: 12

    QtObject {
        id: privateCtrl
        function check_number(num) {
            let a = Math.round(num * 100);
            return a / 100;
        }

        readonly property string shortText: root.name
        readonly property string posText: "(" + check_number(root.position.x) + ", " + check_number(root.position.y) + ")"
    }

    Rectangle {
        id: indicator
        width: 4
        height: 4
        radius: 2
        color: root.color
        border.width: 0
        x: -2
        y: -2
    }

    onPositionChanged: {
        root.x = root.position.x;
        root.y = root.position.y;
    }

    Item {
        id: mouseArea
        width: 10
        height: 10
        x: -5
        y: -5
        ToolTip.delay: 0
        ToolTip.text: privateCtrl.shortText + privateCtrl.posText
    }
}
