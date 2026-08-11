import QtQuick
import QtQuick.Templates as T
import Qool

/*!
    \qmltype ScrollIndicator
    \inqmlmodule Qool.Controls
    \brief 基于 T.ScrollIndicator 的 QoolUI 风格滚动指示条。

    \c color 控制指示条颜色；\c alwaysOn 决定常显。\c showIndicator 为
    只读状态：内容不满一屏（size 为 1）时始终隐藏；\c alwaysOn 时恒显；
    否则仅当滚动条 active 且 size 小于 1 时显示。\c scrollPosition 将
    原生 position 重映射（Qore.remap 到 0..1-size），供外部做精确位移。
    指示条尺寸按 \c horizontal 在两套 Binding 间切换（竖条 2x100 /
    横条 100x2，四周留 2px）。

    \section2 两态驱动（刻意设计）
    指示条透明度由 latch 两态驱动：滚动（scrollPosition 变化）后的
    1750ms 窗口内瞬时显现为 1，窗口结束回落常态 visualOpacity
    （alwaysOn 时 0.25，否则 0）。不得改用命令式赋值驱动 opacity——
    赋值会杀死下方绑定（绑定永久失效，showIndicator 变化不再反映到
    透明度）；两态过渡由 BasicNumberBehavior 负责。
*/

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
    // ——对齐 ScrollBar 的 onVisualSizeChanged 触发（2026-08-11 经验回流）。
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
