import QtQuick
import QtQuick.Window
import Qool

Window {
    id: root

    signal accepted
    signal rejected

    property alias header: surface.header
    property alias content: surface.content
    property alias footer: surface.footer

    function open() {
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function accept() {
        root.visible = false;
        root.accepted();
    }

    function reject() {
        root.visible = false;
        root.rejected();
    }

    modality: Qt.WindowModal
    flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"

    // 裸 Window 无 implicit 尺寸，尺寸直接绑 width/height
    width: Math.max(minimumWidth, surface.implicitWidth)
    height: Math.max(minimumHeight, surface.implicitHeight)

    // 最小尺寸 = 背景件切角 + 边框：再小 QoolBox 形状退化
    minimumWidth: surface.backgroundSettings.cutSpaceOnLeft
                  + surface.backgroundSettings.cutSpaceOnRight
                  + surface.backgroundSettings.borderWidth * 2
    minimumHeight: surface.backgroundSettings.cutSpaceOnTop
                   + surface.backgroundSettings.cutSpaceOnBottom
                   + surface.backgroundSettings.borderWidth * 2

    maximumWidth: width
    maximumHeight: height

    // Connections 而非 onClosing：使用处的 onClosing 会覆盖直接 handler，veto 静默失效
    Connections {
        target: root
        function onClosing(close) {
            close.accepted = false;
            root.reject();
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.reject()
    }

    DialogSurface {
        id: surface
        anchors.fill: parent
        title: root.title
    }
}
