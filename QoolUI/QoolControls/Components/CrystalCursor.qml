// CrystalCursor：延迟缩放基准件（Qool.Controls.Components）——光标/手柄
// 家族共用骨架：Crystal 菱形 + 缩放展开 + 延迟锁存 + 色外包。
//
// 能力（单一职责——只承载「延迟缩放行为」，定位/色源留消费方）：
// - 根 = Item（消费方摆尺寸，稳定定位锚——footprint 恒定，缩放只作用
//   内部 Crystal）；内部 Qool.Crystal 菱形（自带精确 contains 命中判定，
//   方形四角穿透，无需独立掩码组件）。
// - expanded（bool，默认 true）为唯一行为输入：true 展开（占满根）、
//   false 收缩（常态 = fullSize − delta）。不监听任何值信号——消费方把
//   hover/pressed/值变化「或」成一个 bool 注入。
// - 两层锁存职责正交（本件 = 下游电平防抖）：expanded 已是消费方归约后
//   的持续电平（hover/pressed 天然持续；值变化等瞬时事件由消费方经
//   TimerLatch 转成持续电平——上游脉冲→电平，见 Slider/ChannelCrystalSlider
//   的 latch）。本件 delay 只做电平回落的防抖（短、通用），不做长保持——
//   长保持是消费方交互语义（各自归约，ADR-0016 拒绝 latchTarget 进基准件）。
// - 缩放经 ItemAnimatedResizer（from = fullSize−delta → to = fullSize），
//   动画门控 animationEnabled（父链继承回退 Style）。
// - 色外包：color/borderColor 公开属性，默认绑 Style（color = accent、
//   borderColor = recommendForeground(color)，对齐 Qool.Crystal 现成默认）。
// - 契约裁剪：无 defaultValue/reset/双击；无 x/y 定位、无 center 坐标
//   （定位留消费方，中心坐标经 CenterPlacer 组合——ADR-0015）。
//
// 命中域（实现风险契约）：内部 Crystal anchors.centerIn 根中心（缩放展开
// 时亦然）——其自带 contains 域与旧 containmentMask 语义等价（菱形外
// 轨道/表面按压贯通）。

import QtQuick
import Qool

Item {
    id: root

    // 唯一行为输入：true 展开（立即）、false 收缩（经 delay 锁存窗口回落）
    property bool expanded: true

    // 缩放增量：常态 = fullSize − delta、展开 = fullSize。默认取家族
    // 收缩惯例（Qore.bound(3, fullSize×25%, 25)——Slider shrinkSize 同款）。
    property real delta: Qore.bound(3, root.fullSize * 0.25, 25)

    // 防抖窗口：expanded 置 false 后保持展开的时长（放大无延迟——展开
    // 是主动反馈须跟手即时；收缩防抖防状态快速变化闪缩）。值变化长保持
    // 窗口由消费方归约提供（本件 delay 不做长保持）。
    property int delay: Style.transitionDuration

    // 色外包（对齐 Qool.Crystal 现成默认）：填充色 + 自动对比描边
    property color color: Style.accent
    property color borderColor: ThemeHQ.recommendForeground(root.color)

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 显式默认尺寸（QML Item 未显式赋值时 width/height 读取为 undefined——
    // fullSize 依赖它们须确定性；消费方摆实际尺寸覆盖默认）
    width: 0
    height: 0

    // 完整边长 = min(根 w,h)（长方形根 → 菱形内切短边居中）
    readonly property real fullSize: Math.min(root.width, root.height)
    // 内部 Crystal 当前边长（动态——常态/展开/动画中）
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

    // —— 缩放（延迟缩放行为）：resized = 锁存后结果——expanded=true 恒
    // 展开（自洽、立即），false 经 delay 窗口后才收缩（防抖不闪缩）——
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

    // —— 菱形（自带 contains 命中域）：居中于根（缩放展开中心不动）、
    // 尺寸随 cResizer、色外包注入；色变化动画门控（外部改色平滑过渡）——
    Crystal {
        id: crystal
        width: cResizer.width
        height: cResizer.height
        anchors.centerIn: parent
        color: root.color
        borderColor: root.borderColor

        BasicColorBehavior on color {
            enabled: root.animationEnabled
        }

        BasicColorBehavior on borderColor {
            enabled: root.animationEnabled
        }
    }
}
