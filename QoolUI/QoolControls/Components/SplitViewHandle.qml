import QtQuick
import QtQuick.Controls
import Qool

Item {
    id: root

    property color color: Style.text
    property color pressedColor: Style.highlight
    property color hoveredColor: Style.toolTipBase
    property real edgeSpacing: 2
    property real lengthFactor: 0.5
    property int animateDuration: Style.instantDuration

    implicitWidth: 8
    implicitHeight: 8

    readonly property SplitView view: parent

    Rectangle {
        id: box
        color: {
            if (root.SplitHandle.pressed)
                return root.pressedColor
            if (root.SplitHandle.hovered)
                return root.hoveredColor
            return root.color
        }

        opacity: {
            if (root.SplitHandle.pressed)
                return 1
            if (root.SplitHandle.hovered)
                return 0.5
            return 0.15
        }

        BasicColorBehavior on color {
            duration: root.animateDuration
        }
        BasicNumberBehavior on opacity {
            duration: root.animateDuration
        }
    }

    containmentMask: box

    Binding {
        when: view && view.orientation === Qt.Horizontal
        box.x: root.edgeSpacing
        box.y: (root.height - box.height) / 2
        box.width: root.width - root.edgeSpacing * 2
        box.height: root.height * root.lengthFactor
        box.radius: box.width / 2
    }

    Binding {
        when: view && view.orientation === Qt.Vertical
        box.x: (root.width - box.width) / 2
        box.y: root.edgeSpacing
        box.width: root.width * root.lengthFactor
        box.height: root.height - root.edgeSpacing * 2
        box.radius: box.height / 2
    }
}
