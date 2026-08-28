import QtQuick
import QtQuick.Controls as QC

QC.ScrollView {
    id: root

    // 滚动条：Qool 主题（非 Qt 默认样式）。几何 = 官方 ScrollView 样式
    // 公式（parent/x/y/availableHeight/active 联动——照抄 Basic 样式）：
    // ScrollView 附加机制只转发 position/size/active、不设几何；官方
    // Basic/Windows 样式的滚动条公式写在样式层；实例级附加（内置）覆盖
    // 样式默认后公式由本处提供，否则落在左上角（官方 Basic ScrollBar
    // 同款问题）。
    ScrollBar.vertical: ScrollBar {
        parent: root
        x: root.mirrored ? 0 : root.width - width
        y: root.topPadding
        height: root.availableHeight
        active: root.ScrollBar.horizontal.active
    }
    ScrollBar.horizontal: ScrollBar {
        parent: root
        x: root.leftPadding
        y: root.height - height
        width: root.availableWidth
        active: root.ScrollBar.vertical.active
    }

    // 内容让位：滚动条可见时内容区扣除其占用（不可见时 effectiveScrollBar*
    // 归零，让位自动消失）
    rightPadding: effectiveScrollBarWidth + padding
    bottomPadding: effectiveScrollBarHeight + padding
}
