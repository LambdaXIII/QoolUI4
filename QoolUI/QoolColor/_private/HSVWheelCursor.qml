// HSVWheelCursor：二维取色表面光标（Crystal 菱形 + 当前实色 + 三态展开 +
// 掩码 + 中心单向定位）。HSVWheel 的光标组件——定位完全由数据派生
// （centerx/centery = position(hue,sat) 单向绑定），非被拖动对象。
//
// 与 ColorChannelSliderHandle 的差异（表面场景 vs 一维滑块场景）：
// - 定位单向派生（centerx/centery——组件中心坐标），无 x/y↔center/centery
//   双同步环（旧 ColorCursor 的刻意不对称写回是死代码包袱，本件丢弃）。
// - x/y 是 centerx/centery 的派生副产品（x = centerx - width/2），不参与
//   定位——消费方只提供中心坐标。
// - 输出中心坐标在圆内（值合法 → position 有效），光标外观保护靠值
//   合法性而非坐标硬限制。
//
// 外观反馈结构（对齐 ColorChannelSliderHandle——两光标同族，维护心智
// 负担小）：Qool.Crystal + 三态展开（hover / userInteracting / 值变化
// 锁存 TimerLatch）驱动 ItemAnimatedResizer + 当前实色 solidColor +
// 自动对比描边（ThemeHQ.recommendForeground）+ 菱形命中掩码。
//
// 易误解点（勿改）
// - 掩码用 Crystal4ContainmentMask（菱形命中域——光标不拦截菱形外的按压，
//   InteractingArea 圆盘拖动贯通）。
// - 展开反馈的"值变化锁存"经 latchTarget 触发（消费方把
//   colorAssistant 传入——assistant 改色即触发锁存滑动窗口）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

Item {
    id: root

    // 输入（HSVWheel 注入）
    property bool animationEnabled: false
    property color currentColor: "white"
    property bool userInteracting: false
    // 值变化锁存目标（assistant——改色触发锁存展开）
    // 值变化锁存目标（ColorAssistant——改色触发锁存展开）。
    // 注意：assistant 是 QObject 非 Item——声明 QtObject 类型，
    // 消费方须接线（否则锁存永不触发）。
    property QtObject latchTarget: null
    // 组件边长（菱形边长）
    property real size: 20
    // 展开膨胀量（小件收缩、大件限幅——Qore.bound 惯例）
    readonly property real expandDelta: Qore.bound(4, root.size * 0.35, 15)

    // —— 中心单向定位：centerx/centery 是数据派生输入（消费方绑定
    // position(hue,sat)）；x/y 只是派生输出（中心对齐），不参与定位。
    property real centerx
    property real centery
    readonly property point centerPoint: Qt.point(centerx, centery)

    width: size
    height: size
    x: centerx - width / 2
    y: centery - height / 2

    // —— 值变化锁存：assistant 改色 → 展开保持（滑动窗口）——与 hover/
    // userInteracting 共同驱动 resized（改值瞬间避免收缩再展开闪动）。
    TimerLatch {
        id: latch
        interval: Style.movementDuration * 2
        Connections {
            target: root.latchTarget
            function onColorChanged() {
                latch.trigger()
            }
        }
    }

    // —— 展开反馈：常态 = size、展开 = size + expandDelta；动画门控
    // animationEnabled。三态（hover / userInteracting / 锁存）任一成立即展开。
    ItemAnimatedResizer {
        id: cResizer
        enabled: root.enabled
        animationEnabled: root.animationEnabled
        fromWidth: root.size
        fromHeight: root.size
        toWidth: root.size + root.expandDelta
        toHeight: root.size + root.expandDelta
        resized: hoverer.hovered || root.userInteracting || latch.active
    }

    // —— 水晶菱形：当前实色（solidColor）+ 自动对比描边；尺寸随 cResizer。
    // 色/描边变化动画门控（外部改色平滑过渡）。
    Crystal {
        id: crystal
        width: cResizer.width
        height: cResizer.height
        anchors.centerIn: parent
        color: root.currentColor
        borderColor: ThemeHQ.recommendForeground(root.currentColor)

        BasicColorBehavior on color {
            enabled: root.animationEnabled
        }

        BasicColorBehavior on borderColor {
            enabled: root.animationEnabled
        }

        // 仅 hover/光标反馈：NoButton 不拦截按压（圆盘拖动贯通——掩码
        // 菱形域内同样有效）；disabled 时无反馈。
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: Qt.CrossCursor
        }

        HoverHandler {
            id: hoverer
            enabled: root.enabled
        }
    }

    // 菱形命中域（水晶中心 = 组件中心）：光标不拦截菱形外的圆盘按压
    containmentMask: Crystal4ContainmentMask {
        width: root.width
        height: root.height
        // centerPoint 是掩码本地坐标（掩码是光标 (0,0) 的子项——
        // 本地 == 光标本地），非父/轮盘坐标——勿用 root.centerPoint
        //（父坐标系），否则菱形域被光标偏移、对光标内任意点恒不命中。
        centerPoint: Qt.point(root.width / 2, root.height / 2)
    }
}
