import QtQuick
import QtQuick.Controls as QC

// Qool.Controls.ScrollView：Qool 系列滚动视图（带 Qool 主题滚动条）——官方
// 成品 ScrollView（QC 版）+ 预设 Qool 主题滚动条，宿主零配置获得 Qool 主题
// 滚动（拖动/滚轮/主题外观）。
//
// 根 = QC.ScrollView（官方成品，非 T.ScrollView——T 版不转发
// position/size 给附加滚动条、无样式让位；QC 版转发/内容让位全免费）。
// 滚动条 = ScrollBar（同模块——Qool.Controls，
// T.ScrollBar 子类基础原件），几何按官方 ScrollView 样式公式
//（parent/x/y/availableHeight + active 双条联动——官方样式层公式上移为
// 内置，跨 Basic/Windows 样式一致）。
//
// 内容让位显式声明（rightPadding/bottomPadding = effectiveScrollBar
// 尺寸 + padding——照抄 Windows 样式公式）：Basic 样式无此设置，不显式
// 声明则 Basic 样式下滚动条遮内容、行为随宿主样式漂移。

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

    // 内容让位：滚动条可见时内容区扣除其占用（跨样式一致——官方
    // Windows 样式同款公式，Basic 样式无此设置；滚动条不可见时
    // effectiveScrollBar* 归零，让位自动消失）。
    rightPadding: effectiveScrollBarWidth + padding
    bottomPadding: effectiveScrollBarHeight + padding
}
