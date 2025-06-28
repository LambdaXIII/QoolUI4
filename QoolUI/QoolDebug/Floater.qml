import QtQuick
import QtQuick.Controls

Item {
    id: root

    property Item floatingLayer: Overlay.overlay

    property Item floatingItem: Item {}

    readonly property point floatingPosition: pCtrl.floatingPosition

    QtObject {
        id: pCtrl
        property point floatingPosition
        function refreshFloatingPosition() {
            if (!root.floatingLayer)
                return
            pCtrl.floatingPosition = root.floatingLayer.mapFromItem(
                        root.parent, root.x, root.y)
        }
    }

    Connections {
        target: root
        function onParentChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onXChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onYChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onFloatingLayerChanged() {
            pCtrl.refreshFloatingPosition()
        }
    }

    Connections {
        target: root.parent
        function onXChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onYChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onWidthChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onHeightChanged() {
            pCtrl.refreshFloatingPosition()
        }
    }

    Connections {
        target: root.floatingLayer
        function onXChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onYChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onWidthChanged() {
            pCtrl.refreshFloatingPosition()
        }
        function onHeightChanged() {
            pCtrl.refreshFloatingPosition()
        }
    }

    Binding {
        when: root.floatingLayer && root.floatingItem
        root.floatingItem.parent: root.floatingLayer
        root.floatingItem.width: root.width
        root.floatingItem.height: root.height
        root.floatingItem.x: root.floatingPosition.x
        root.floatingItem.y: root.floatingPosition.y
        root.floatingItem.z: root.z
        root.floatingItem.opacity: root.opacity
        root.floatingItem.visible: root.visible
    }

    implicitWidth: floatingItem.implicitWidth
    implicitHeight: floatingItem.implicitHeight

    Component.onCompleted: {
        pCtrl.refreshFloatingPosition()
    }
}
