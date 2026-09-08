import QtQuick
import QtQuick.Window
import Qool
import Qool.Controls.Components

// QoolDialog：预置 DialogSurface 的对话框窗口壳（契约见 ADR-0021 与参考文档）。
Window {
    id: root

    readonly property alias surface: dlgSurface

    // 默认属性重定向：写在 QoolDialog 里的子元素进入 surface 内容区
    default property alias content: dlgSurface.contentData

    signal accepted
    signal rejected

    function open() {
        root.visible = true
    }

    function close() {
        root.visible = false
    }

    function accept() {
        root.visible = false
        root.accepted()
    }

    function reject() {
        root.visible = false
        root.rejected()
    }

    modality: Qt.WindowModal
    flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.FramelessWindowHint
    color: "transparent"

    // 不重声明 title（遮蔽 Window.title 语义混乱，ADR-0021 命名契约）；
    // Window.title 跟随 surface.title，供任务栏/无障碍使用
    title: dlgSurface.title

    // 裸 Window 无 implicit 尺寸——width/height 直接绑定 surface 隐式尺寸
    // （下限 200×200 照 QoolWindowBasic 先例）；显式赋值即断开绑定生效
    width: Math.max(200, dlgSurface.implicitWidth)
    height: Math.max(200, dlgSurface.implicitHeight)

    // minimum=maximum 跟随当前尺寸：禁交互 resize、不锁程序化赋值
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height

    onClosing: function (close) {
        close.accepted = false
        reject()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.reject()
    }

    DialogSurface {
        id: dlgSurface
        anchors.fill: parent
    }
}
