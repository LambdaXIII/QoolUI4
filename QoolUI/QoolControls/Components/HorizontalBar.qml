import QtQuick
import QtQuick.Templates as T
import Qool

Item {
    id: root

    property color color: palette.base

    property Component foreground: internalFG
    property Item background: Item {}

    property real percentage: 1
    property int alignment: Qt.AlignHCenter

    implicitWidth: Math.max(100, fgLoader.implicitWidth)
    implicitHeight: Math.max(10, fgLoader.implicitHeight)

    Component {
        id: internalFG
        Rectangle {
            border.width: 0
            color: root.color
            layer.enabled: true
            radius: Math.min(4, height / 2)
        }
    }

    Item {
        id: fgClipper
        width: root.percentage * root.width
        height: root.height
        clip: true
        readonly property point contentPos: mapFromItem(root, 0, 0)

        Loader {
            id: fgLoader
            sourceComponent: root.foreground
            width: root.width
            height: root.height
            x: fgClipper.contentPos.x
            y: fgClipper.contentPos.y
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
        root.background.width: root.width
        root.background.height: root.height
    }
}
