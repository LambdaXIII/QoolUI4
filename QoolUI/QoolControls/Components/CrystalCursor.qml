import QtQuick
import Qool

Item {
    id: root

    property bool expanded: true

    property real delta: Qore.bound(3, root.fullSize * 0.25, 25)

    property int delay: Style.transitionDuration

    property color color: Style.accent
    property color borderColor: ThemeHQ.recommendForeground(root.color)

    // 显式默认尺寸（Item 未显式赋值时 width/height 为 undefined——fullSize
    // 依赖它们须确定性；消费方摆实际尺寸覆盖默认）
    width: 0
    height: 0

    readonly property real fullSize: Math.min(root.width, root.height)
    readonly property real size: crystal.width

    // —— 延迟锁存：expanded 变化触发、窗口后回落（防抖）——
    TimerLatch {
        id: latch
        interval: root.delay
        Connections {
            target: root
            function onExpandedChanged() {
                latch.trigger();
            }
        }
    }

    // —— 缩放（延迟缩放行为）：resized = 锁存后结果——
    ItemAnimatedResizer {
        id: cResizer
        enabled: root.enabled
        animationEnabled: true
        fromWidth: root.fullSize - root.delta
        fromHeight: root.fullSize - root.delta
        toWidth: root.fullSize
        toHeight: root.fullSize
        resized: root.expanded || latch.active
    }

    // —— 菱形（自带 contains 命中域）：居中于根、尺寸随 cResizer、色外包注入——
    Crystal {
        id: crystal
        width: cResizer.width
        height: cResizer.height
        anchors.centerIn: parent
        color: root.color
        borderColor: root.borderColor

        BasicColorBehavior on color {
            enabled: root.Style.animationEnabled
        }

        BasicColorBehavior on borderColor {
            enabled: root.Style.animationEnabled
        }
    }
}
