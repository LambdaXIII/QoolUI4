import QtQuick
import Qool
import Qool.Controls.Components

// DialogSurface：容器无关的对话框表面件（契约见 ADR-0021 与参考文档）。
// 布局/标题/内容机制全部继承 BasicControl，仅覆写背景四 token。
BasicControl {
    id: root

    backgroundSettings: QoolBoxSettings {
        cutSizeTL: root.Style.dialogCutSize
        borderWidth: root.Style.dialogBorderWidth
        borderColor: root.Style.accent
        fillColor: root.Style.window
    }
}
