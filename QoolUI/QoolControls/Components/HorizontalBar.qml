import QtQuick
import QtQuick.Templates as T
import Qool

Item {

    id: root

    property color color: palette.base
    property color alternateColor: palette.alternateBase

    property Component foreground: internalFG
    property Item background: Item {}

    property real percentage: 1
    property int alignment: Qt.AlignHCenter

    implicitWidth: 100
    implicitHeight: 10

    Component {
        id: internalFG
        Rectangle {
            border.width: 0
            color: root.color
            layer.enabled: true
            ParallelVerticalBars {
                width: parent.width
                height: parent.height
                barWidth: 4
                barSpacing: 20
                color: root.alternateColor
            }
        }
    }

    NumberRanger {
        id: ranger
        top: 1.0
        bottom: 0.0
    }

    Item {
        id: fgClipper
        width: ranger.validate(root.percentage) * root.width
        height: root.height
        clip: true
        readonly property point contentPos: mapFromItem(root, 0, 0)

        Loader {
            sourceComponent: root.foreground
            width: root.width
            height: root.height
            x: contentPos.x
            y: contentPos.y
        }
    }

    Binding {
        when: root.alignment == Qt.AlignHCenter
        target: fgClipper
        property: "x"
        value: (root.width - fgClipper.width) / 2
    }

    Binding {
        when: root.alignment == Qt.AlignRight
        target: fgClipper
        property: "x"
        value: root.width - fgClipper.width
    }

    Binding {
        when: root.background
        background.width: root.width
        background.height: root.height
    }
}
