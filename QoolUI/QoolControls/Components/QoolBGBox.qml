import QtQuick
import Qool

QoolBox {
    id: root

    property string title

    property Item label: BasicControlTitleText {
        text: root.title
        visible: text
    }

    settings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: root.borderColor
        fillColor: root.backgroundColor
    }

    Item {
        id: dummyTitle
        x: root.settings.borderWidth + root.control.leftSpace
        y: root.settings.borderWidth
        width: root.width - root.settings.borderWidth * 2
               - root.control.leftSpace - root.control.rightSpace
        implicitHeight: root.control.topSpace - root.settings.borderWidth
    }

    Binding {
        when: root.label && root.label.visible
        root.label.parent: dummyTitle
        root.label.anchors.top: dummyTitle.top
        root.label.anchors.right: dummyTitle.right
        root.label.width: Math.min(dummyTitle.width, root.label.implicitWidth)
        dummyTitle.height: root.label.height
    }

    readonly property real topSpace: dummyTitle.x + dummyTitle.height + root.settings.borderWidth
    readonly property real leftSpace: root.control.leftSpace + root.settings.borderWidth
    readonly property real rightSpace: root.control.rightSpace + root.settings.borderWidth
    readonly property real bottomSpace: root.control.bottomSpace + root.settings.borderWidth

    implicitHeight: root.settings.borderWidth * 2 + root.control.topSpace + root.control.bottomSpace
    implicitWidth: root.settings.borderWidth * 2 + root.control.leftSpace + root.control.rightSpace
}
