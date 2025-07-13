import QtQuick
import Qool

Item {
    id: root

    property OctagonSettings settings: OctagonSettings {
        cutSize: Style.controlCutSize
        borderWidth: Style.controlBorderWidth
        borderColor: Style.accent
        fillColor: Style.dark
    }
    property alias cutSize: root.settings.cutSize

    property Item fillItem: null

    readonly property alias shape: loader.item
    property OctagonShapeHelper control: OctagonShapeHelper {
        settings: root.settings
    }

    property bool round: false

    Component {
        id: boxShape
        OctagonShape {}
    }

    Component {
        id: roundShape
        OctagonRoundedShape {}
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.round ? roundShape : boxShape
    }

    Binding {
        when: loader.item
        target: loader.item
        property: "settings"
        value: root.settings
    }

    Binding {
        when: loader.item
        target: loader.item
        property: "fillItem"
        value: root.fillItem
    }

    Binding {
        when: loader.item?.control ?? false
        target: root
        property: "control"
        value: loader.item.control
    }

    containmentMask: loader.item
}
