import QtQuick
import QtQuick.Templates as T
import Qool

// 两态驱动（刻意设计）：透明度由 latch 两态驱动——滚动后 1750ms 窗口内
// 瞬时显现为 1，窗口结束回落常态 visualOpacity。不得改用命令式赋值驱动
// opacity（会杀死下方绑定）；过渡由 BasicNumberBehavior 负责。详细契约见
// docs/reference/Qool.Controls/ScrollIndicator.md。

T.ScrollIndicator {
    id: root

    property color color: Style.highlight

    property bool alwaysOn: true

    readonly property bool showIndicator: {
        if (root.size === 1)
            return false;
        if (root.alwaysOn)
            return true;
        return root.active && root.size < 1.0;
    }

    readonly property real scrollPosition: {
        return Qore.remap(root.position, 0, 1 - root.size);
    }

    minimumSize: 0.1

    TimerLatch {
        id: latch
        interval: 1750
        readonly property real visualOpacity: root.showIndicator ? 0.25 : 0
    }

    onScrollPositionChanged: latch.trigger()
    // size 突变（内容跨过/退出一屏，size 越过 1.0）时同样给一次显现反馈
    // ——对齐 ScrollBar 的 onVisualSizeChanged 触发。
    onVisualSizeChanged: latch.trigger()

    contentItem: Rectangle {
        id: indicator
        color: root.color
        // 半圆头（radius = 半高）——与 ScrollBar/Qt 官方 Basic 样式一致；
        // 不取 max 圆角：固定 2px 尺寸下两者视觉等价，但尺寸泛化（宿主
        // 自定义宽度）时 max 会超半高、端部形态依赖 Qt 对超半高 radius 的
        // 处理，/2 则任意尺寸下都是标准半圆头。
        radius: Math.floor(Math.min(width, height) / 2)
        // 两态驱动：latch 锁存中（滚动后 1750ms 窗口）瞬时显现为 1，
        // 窗口结束回落常态 visualOpacity。不能改用命令式赋值驱动 opacity
        // ——那会杀死下方绑定（赋值后 binding 永久失效，showIndicator
        // 变化不再反映）；behavior 负责两态过渡。
        opacity: latch.active ? 1 : latch.visualOpacity
        // 过渡用 transitionDuration（较 ScrollBar 的 movementDuration 快）——
        // 指示条是轻量辅助件，瞬时反馈应快于主滚动条的移动动画。
        BasicNumberBehavior on opacity {
            duration: root.Style.transitionDuration
        }
    }//contentItem

    implicitWidth: leftPadding + implicitContentWidth + rightPadding
    implicitHeight: topPadding + implicitContentHeight + bottomPadding

    Binding {
        when: !root.horizontal
        indicator.implicitWidth: 2
        indicator.implicitHeight: 100
        root.leftPadding: 2
        root.rightPadding: 2
    }
    Binding {
        when: root.horizontal
        indicator.implicitWidth: 100
        indicator.implicitHeight: 2
        root.topPadding: 2
        root.bottomPadding: 2
    }
}
