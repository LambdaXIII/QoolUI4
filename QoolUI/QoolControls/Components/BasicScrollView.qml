import QtQuick
import QtQuick.Controls as QC

// Qool.Controls.Components.BasicScrollView：Qool 系列滚动视图基底——官方
// 成品 ScrollView（QC 版）+ 预设 Qool 主题滚动条，宿主零配置获得 Qool 主题
// 滚动（拖动/滚轮/主题外观）。
//
// 根 = QC.ScrollView（官方成品，非 T.ScrollView——实测 T 版不转发
// position/size 给附加滚动条、无样式让位；QC 版转发/内容让位全免费，
// 2026-08-11）。滚动条 = ScrollBar（同模块——Qool.Controls.Components，
// T.ScrollBar 子类基础原件），几何按官方 ScrollView 样式公式
//（parent/x/y/availableHeight + active 双条联动——官方样式层公式上移为
// 内置，跨 Basic/Windows 样式一致）。
//
// 内容让位显式声明（rightPadding/bottomPadding = effectiveScrollBar
// 尺寸 + padding——照抄 Windows 样式公式）：Basic 样式无此设置，不显式
// 声明则 Basic 样式下滚动条遮内容、行为随宿主样式漂移。

/*!
    \qmltype BasicScrollView
    \inqmlmodule Qool.Controls.Components
    \inherits ScrollView

    \brief 带 Qool 主题滚动条的滚动视图基底——官方 ScrollView 成品
    （Controls 版）+ 预设 Qool 主题滚动条。

    BasicScrollView 是 Qool 系列滚动视图的基础件：官方 Qt Quick Controls
    的 \l ScrollView 全部行为（内容尺寸自动接驳、背景不随内容滚动、自动
    裁剪、滚动转发），加上预设的 Qool 主题滚动条（垂直/水平均为 Qool
    ScrollBar——非 Qt 默认样式）——宿主零配置获得 Qool 主题滚动。

    \section1 接口兼容性

    继承 Qt Quick Controls 的 \l ScrollView（其继承 Pane）——官方 API
    全部可用（contentData / effectiveScrollBarWidth /
    effectiveScrollBarHeight 等），宿主可参照官方文档。本类型不改变官方
    行为，仅预设滚动条与内容让位，以下仅文档化 Qool 设置部分。

    \section1 滚动条

    内置垂直/水平滚动条——均为 Qool ScrollBar（主题样式、可交互拖动）。
    默认 AsNeeded 策略（内容不足视口时隐藏）；布局按官方 ScrollView 样式
    公式（垂直贴右侧、水平贴底部、随内容区全高/全宽、双条互让）。滚动条
    为官方 ScrollView 附加属性实例（ScrollBar.vertical /
    ScrollBar.horizontal）——宿主可参照官方 ScrollView 文档的附加属性
    语义访问。

    \section1 行为

    \list
    \li 内容区自动让位：滚动条可见时内容区宽度/高度扣除滚动条占用
        （rightPadding/bottomPadding = 滚动条尺寸 + padding）——滚动条
        不遮内容，跨样式一致（官方 Basic 样式无此设置，本类型显式声明）。
    \li 滚动条策略经官方 policy 属性控制：AlwaysOff 时完全隐藏且内容区
        不缩（effectiveScrollBar 尺寸归零，让位自动消失）。
    \li 默认尺寸由内容决定（官方 ScrollView 行为）：无内容时隐式尺寸为
        0，宿主应给定尺寸（width/height 或 anchors.fill）。
    \endlist
*/

QC.ScrollView {
    id: root

    // 滚动条：Qool 主题（非 Qt 默认样式）。几何 = 官方 ScrollView 样式
    // 公式（parent/x/y/availableHeight/active 联动——照抄 Basic 样式）：
    // 2026-08-11 实测——ScrollView 附加机制只转发 position/size/active 不设
    // 几何；官方 Basic/Windows 样式的滚动条公式写在样式层；实例级附加
    //（内置）覆盖样式默认后公式由本处提供，否则落在左上角（官方 Basic
    // ScrollBar 同款问题——实测对照一致）。
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
