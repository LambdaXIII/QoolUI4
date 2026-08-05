import QtQuick
import QtQuick.Templates as T

Item {
    id: root

    property Item target: T.Overlay.overlay
    property Item content

    readonly property point globalPos: pCtrl.globalPos
    readonly property point floatingPos: pCtrl.floatingPos

    QtObject {
        id: pCtrl
        property point globalPos
        property point floatingPos
        function updatePos() {
            if (root.parent)
                pCtrl.globalPos = root.parent.mapToGlobal(root.x, root.y)
            else
                pCtrl.globalPos = root.mapToGlobal(0, 0)

            if (root.target)
                pCtrl.floatingPos = root.target.mapFromGlobal(globalPos.x,
                                                              globalPos.y)
            else
                pCtrl.floatingPos = Qt.point(0, 0)
        }
    }

    Connections {
        target: root
        enabled: Component.completed
        function onParentChanged() {
            pCtrl.updatePos()
        }
        function onXChanged() {
            pCtrl.updatePos()
        }
        function onYChanged() {
            pCtrl.updatePos()
        }
        function onTargetChanged() {
            pCtrl.updatePos()
        }
        function onWidthChanged() {
            pCtrl.updatePos()
        }
        function onHeightChanged() {
            pCtrl.updatePos()
        }
    }

    Connections {
        target: root.parent
        enabled: Component.completed
        function onXChanged() {
            pCtrl.updatePos()
        }
        function onYChanged() {
            pCtrl.updatePos()
        }
        function onWidthChanged() {
            pCtrl.updatePos()
        }
        function onHeightChanged() {
            pCtrl.updatePos()
        }
        function onParentChanged() {
            pCtrl.updatePos()
        }
        function onWindowChanged() {
            pCtrl.updatePos()
        }
    }

    Connections {
        target: root.target
        enabled: Component.completed
        function onXChanged() {
            pCtrl.updatePos()
        }
        function onYChanged() {
            pCtrl.updatePos()
        }
        function onWidthChanged() {
            pCtrl.updatePos()
        }
        function onHeightChanged() {
            pCtrl.updatePos()
        }
        function onParentChanged() {
            pCtrl.updatePos()
        }
        function onWindowChanged() {
            pCtrl.updatePos()
        }
    }

    Binding {
        when: root.target && root.content
        root.content.parent: root.target
        root.content.width: root.width
        root.content.height: root.height
        root.content.x: root.floatingPos.x
        root.content.y: root.floatingPos.y
        root.content.z: root.z
        root.content.opacity: root.opacity
        root.content.visible: root.visible
        root.content.enabled: root.enabled
    }

    implicitWidth: content?.implicitWidth ?? 100
    implicitHeight: content?.implicitHeight ?? 100

    // 公开刷新入口：updatePos 仅在"自身 x/y 变化"或"父级 x/y 变化"
    // 时自动触发（见上方 Connections）。父级被整体平移时（如父级
    // 经 anchors 跟随祖父移动，自身相对坐标不变），自动触发链断开，
    // 需要外部显式调用本方法（见 RectResizer 的父级几何监听）。
    function refresh() {
        pCtrl.updatePos()
    }

    Component.onCompleted: pCtrl.updatePos()
}
