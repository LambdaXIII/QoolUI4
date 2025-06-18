import QtQuick
import Qool

Item {
    id: root

    property Item item: parent as Item
    property Item relativeTo: null

    property int anchorPosition: Qore.Center
    property int targetAnchorPosition: Qore.Center

    property int xOffset: 0
    property int yOffset: 0

    readonly property bool isValid: root.item !== null && root.relativeTo !== null
    readonly property bool activated: root.isValid && root.enabled

    visible: false

    Binding {
        when: root.activated
        target: root.item
        property: "x"
        value: {}
    }
}
