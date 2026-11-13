import QtQuick
import QtQuick.Window
import Qool

Window {
    id: root

    property alias header: surface.header
    property alias content: surface.content
    property alias footer: surface.footer

    modality: Qt.WindowModal
    flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"

    // 裸 Window 无 implicit 尺寸，尺寸直接绑 width/height
    width: Math.max(minimumWidth, surface.implicitWidth)
    height: Math.max(minimumHeight, surface.implicitHeight)

    // 最小尺寸 = 背景件切角 + 边框：再小 QoolBox 形状退化
    minimumWidth: surface.backgroundSettings.cutSpaceOnLeft + surface.backgroundSettings.cutSpaceOnRight + surface.backgroundSettings.borderWidth * 2
    minimumHeight: surface.backgroundSettings.cutSpaceOnTop + surface.backgroundSettings.cutSpaceOnBottom + surface.backgroundSettings.borderWidth * 2

    // maximumWidth: width
    // maximumHeight: height

    signal accepted
    signal rejected

    // Connections 而非 onClosing：使用处的 onClosing 会覆盖直接 handler，veto 静默失效
    Connections {
        target: root
        function onClosing(close) {
            close.accepted = false;
            root.reject();
        }
    }

    // Esc ≡ Cancel：结果与 Cancel（RejectRole → rejected）一致——直接 reject()。
    // 应用级快捷键而不是窗口级：对话框是独立的 frameless Window，平台不保证
    // 它会成为活动窗口（实测 Windows 上 active 为 false）——窗口级快捷键此时
    // 永不匹配，Esc 静默失效。只在本窗口可见时生效。
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: root.reject()
    }

    DialogSurface {
        id: surface
        anchors.fill: parent
        title: root.title
    }

    function open() {
        root.visible = true;
        root.requestActivate();
        // 窗口刚映射时首次激活请求可能落空（平台窗口尚未就绪），补一次
        Qt.callLater(root.requestActivate);
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
}
