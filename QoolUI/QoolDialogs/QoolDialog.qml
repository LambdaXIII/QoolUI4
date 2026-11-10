import QtQuick
import QtQuick.Window
import QtQuick.Templates as T
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

    // Esc ≡ Cancel：不直接关窗，而是走 Cancel 按钮的同一条通道
    // （按钮 clicked → 盒按 role 分发 rejected() → 使用者的接线），
    // 没有 Cancel 按钮时退回 reject()，保证永远关得掉。
    function cancel() {
        const button = root.findCancelButton(surface);
        if (button && button.enabled && button.visible) {
            button.click();
            return;
        }
        root.reject();
    }

    // 槽位子树里第一个 RejectRole 按钮（Cancel 的标准角色）。
    // 只认按钮（有 click()）再读 attached role，避免给普通项挂 attached 对象。
    function findCancelButton(node) {
        const kids = node.children;
        for (let i = 0; i < kids.length; ++i) {
            const child = kids[i];
            if (typeof child.click === "function"
                    && child.T.DialogButtonBox.buttonRole === T.DialogButtonBox.RejectRole)
                return child;
            const found = root.findCancelButton(child);
            if (found)
                return found;
        }
        return null;
    }

    // 应用级快捷键而不是窗口级：对话框是独立的 frameless Window，平台不保证
    // 它会成为活动窗口（实测 Windows 上 active 为 false）——窗口级快捷键此时
    // 永不匹配，Esc 静默失效。只在本窗口可见时生效。
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: root.cancel()
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
