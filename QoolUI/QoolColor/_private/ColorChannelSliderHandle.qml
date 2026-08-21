// ColorChannelSliderHandle：通道滑块光标（Crystal 菱形 + 当前实色 + 三态
// 展开 + 掩码 + displayValue 位置动画）。ColorChannelSlider 的 handle
// delegate——共享件，无 per-channel 差异（色源 = assistant.solidColor）。
//
// 易误解点（勿改）
// - 定位须自写（T.Slider 模板不注入 handle 几何）：水平 x 由 displayValue
//   （绑定 slider.visualPosition——RTL 镜像承载）驱动、y 居中；垂直 y 由
//   displayValue 驱动、x 居中。
// - displayValue 是位置动画面：拖动中（pressed）Behavior 被门控关闭、
//   光标跟手；松手/外部改值时平滑过渡（旧 value/displayValue 分离语义）。
// - 三态展开 = hover / pressed / 值变化锁存（TimerLatch——值变化即触发、
//   滑动窗口保持），共同驱动 ItemAnimatedResizer：常态 side−shrinkSize、
//   展开 side——"顶出轨道但不出控件"（轨道收缩 + 法向居中配套）。
// - containmentMask 用 Crystal4ContainmentMask（菱形命中域——手柄不拦截
//   菱形外的轨道按压，模板拖动仍贯通）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

Item {
    id: root

    // 输入（ColorChannelSlider 注入——handle delegate 契约）
    property bool animationEnabled: false
    property bool positionAnimated: false
    property bool horizontal: true
    property real leftPadding: 0
    property real topPadding: 0
    property real availableWidth: 150
    property real availableHeight: 25
    property real displayValue: 0
    property real side: 25
    property real shrinkSize: 10
    property color color: "white"
    property bool pressed: false
    property Item latchTarget: null

    width: side
    height: side

    // 定位（模板不注入——自写）：水平 x = leftPadding + displayValue ×
    // (availableWidth − width)、y 居中；垂直对调。displayValue 走
    // visualPosition（RTL 反转 + 垂直恒反转均随模板）
    x: horizontal ? leftPadding + displayValue * (availableWidth - width)
                  : leftPadding + (availableWidth - width) / 2
    y: horizontal ? topPadding + (availableHeight - height) / 2
                  : topPadding + displayValue * (availableHeight - height)

    // 位置动画：displayValue 中间层 + Behavior 门控（pressed 关闭——
    // 拖动中跟手无滞后；positionAnimated 由宿主门控——创建/播种期不动画、
    // animationEnabled 关闭即跳变）
    BasicNumberBehavior on displayValue {
        enabled: root.positionAnimated && !root.pressed
        duration: Style.movementDuration
    }

    // 值变化锁存：slider value 变化 → 展开保持（滑动窗口）——与 hover/
    // pressed 共同驱动 resized（改值瞬间避免收缩再展开闪动）
    TimerLatch {
        id: latch
        interval: Style.movementDuration * 2
        Connections {
            target: root.latchTarget
            function onValueChanged() {
                latch.trigger()
            }
        }
    }

    // 展开反馈：常态 = side − shrinkSize（与轨道同高贴斜边）、展开 =
    // side（占满法向——顶出轨道但不出控件）；动画门控 animationEnabled
    ItemAnimatedResizer {
        id: cResizer
        enabled: root.enabled
        animationEnabled: root.animationEnabled
        fromWidth: root.side - root.shrinkSize
        fromHeight: root.side - root.shrinkSize
        toWidth: root.side
        toHeight: root.side
        resized: hoverer.hovered || root.pressed || latch.active
    }

    // 水晶菱形：当前实色（solidColor）+ 自动对比描边；尺寸随 cResizer。
    // objectName 供 QML 测试读取（光标实色是公开视觉契约——内部对象零
    // 暴露原则的测试例外，与轨道 objectName 同惯例）。色/描边变化动画
    // 门控（pressed 时即时——拖动反馈所见即所得，外部改色平滑过渡）。
    Crystal {
        id: crystal
        objectName: "handleCrystal"
        width: cResizer.width
        height: cResizer.height
        anchors.centerIn: parent
        color: root.color
        borderColor: ThemeHQ.recommendForeground(root.color)

        BasicColorBehavior on color {
            enabled: root.animationEnabled && !root.pressed
        }

        BasicColorBehavior on borderColor {
            enabled: root.animationEnabled && !root.pressed
        }

        // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动在手柄上仍
        // 有效——掩码菱形域内同样贯通）；disabled 时无反馈
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }

        HoverHandler {
            id: hoverer
            enabled: root.enabled
        }
    }

    // 菱形命中域（水晶中心 = 组件中心）：手柄不拦截菱形外的轨道按压
    containmentMask: Crystal4ContainmentMask {
        width: root.width
        height: root.height
        centerPoint: Qt.point(root.width / 2, root.height / 2)
    }
}
