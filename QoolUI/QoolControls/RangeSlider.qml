// Qool.Controls.RangeSlider：区间滑块（T.RangeSlider 模板 API 兼容）。
//
// 结构：模板 handle（默认透明窄条，激活模板交互——snap/live/键盘/nearest/
// 端点钳制免费）+ Crystal 轨道（background，静态）+ contentItem 内区间盒
// 前景（rangeBox 承载区间几何，hover/值变化锁存展开动画）。
// 前景不设独立 surface 插拔属性——直接置于 contentItem，由 rangeBox 区间
// 盒定位，hover/值变化锁存展开反馈。
//
// 完整契约（几何模型/交互反馈/插拔）见
// docs/reference/Qool.Controls/RangeSlider.md。

import QtQuick
import QtQuick.Templates as T
import Qool

T.RangeSlider {
    id: root
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 前景填充色（rangeCrystal），默认 Style.accent。
    property color color: Style.accent
    // 轨道背景色（轨道以 75% 透明度渲染），默认 Style.buttonText。
    property color backgroundColor: Style.buttonText
    // 前景/轨道描边色——基于 backgroundColor 自动对比推荐（宿主可单独覆盖）。
    property color borderColor: ThemeHQ.recommendForeground(backgroundColor)

    // 尺寸：反向排版策略——模板自带 implicit 公式（background 与 contentItem
    // 的 implicit 尺寸取大者）；组件只给 background 显式 implicit（200×22），
    // contentItem implicit 由前景内容承载。
    implicitWidth: {
        const w1 = leftInset + implicitBackgroundWidth + rightInset;
        const w2 = leftPadding + implicitContentWidth + rightPadding;
        return Math.max(w1, w2);
    }
    implicitHeight: {
        const h1 = topInset + implicitBackgroundHeight + bottomInset;
        const h2 = topPadding + implicitContentHeight + bottomPadding;
        return Math.max(h1, h2);
    }

    SmartObject {
        id: pCtrl
        // 常态收缩量：轨道与前景从全尺寸收缩的量（hover 展开时前景占满
        // 区间盒；轨道恒为常态——静态，不参与交互反馈）。
        readonly property real shrinkSize: Qore.bound(3, root.height * 0.25, 25)
        // 收缩偏移量的一半——轨道垂直居中（收缩后上下各留 shrinkSize/2）。
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    // —— 轨道层：Crystal 六边形（backgroundColor 75% 透明 + borderColor
    // 描边）——全宽、恒为常态高度（不随交互变）+ 垂直居中（y = 收缩偏移/
    // 2）。background 显式 implicit（200×22）供控件 implicit 计算。
    background: Item {
        implicitHeight: 25
        implicitWidth: 150

        Crystal {
            borderColor: root.borderColor
            color: Qt.alpha(root.backgroundColor, 0.75)
            width: parent.width
            height: parent.height - pCtrl.shrinkSize
            y: pCtrl.halfShrinkSpace
        }
    }

    // —— 默认透明 handle（模板 handle 插拔点：宿主替换即自定义端点命中/
    // 视觉/光标）：窄条（宽 = 高/2）——视觉由前景 rangeCrystal 承担，handle
    // 只做模板拖动/键盘的命中基准。
    //
    // 不相交公式：行程 = availableWidth − width×2（扣除两个 handle 的宽），
    // first 从 0 起、second 从 width 起——两个 handle 各自占 width，任意值
    // 下永不相交（端点重合时相邻不重叠）。用 visualPosition（RTL/垂直时
    // 反向）而非 position，与模板一致。y 垂直居中于可用区；z:10 保证盖在
    // contentItem 前景之上、拖动命中不受前景遮挡。
    first.handle: Item {
        height: root.availableHeight
        width: height / 2
        x: root.leftPadding + root.first.visualPosition * (root.availableWidth - width * 2)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        z: 10

        MouseArea {
            enabled: root.enabled
            cursorShape: Qt.SplitHCursor
            acceptedButtons: Qt.NoButton
            anchors.fill: parent
        }
    }

    second.handle: Item {
        height: root.availableHeight
        width: height / 2
        x: root.leftPadding + width + root.second.visualPosition * (root.availableWidth - width * 2)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        z: 10

        MouseArea {
            enabled: root.enabled
            cursorShape: Qt.SplitHCursor
            acceptedButtons: Qt.NoButton
            anchors.fill: parent
        }
    }

    // —— 前景层（contentItem 内）：rangeBox 区间盒承载——x/width 随两端
    // visualPosition（值→位置映射）：左边缘 = first 视觉位、宽 = 区间视觉
    // 宽 + 自身高（多出 height 作尖角外溢/对齐余量）；height = 可用高。
    contentItem: Item {
        // 值变化锁存（TimerLatch）：拖动/键盘/程序化改值后前景保持展开
        // interval（500ms）——任一 handle 值变化即触发（滑动窗口内持续保持），
        // 与 hover 共同驱动 resized（hovered || latch.active），避免改值
        // 瞬间前景收缩再展开的闪动。
        TimerLatch {
            id: latch
            interval: 500
            Connections {
                target: root.first
                function onValueChanged() {
                    latch.trigger();
                }
            }
            Connections {
                target: root.second
                function onValueChanged() {
                    latch.trigger();
                }
            }
        }

        Item {
            id: rangeBox
            height: parent.height

            x: root.first.visualPosition * (parent.width - height)
            width: (parent.width - height) * (root.second.visualPosition - root.first.visualPosition) + height

            // hover 展开反馈驱动源：前景 hover 即展开、离开收缩——与下方
            // latch（值变化锁存）共同驱动 resized（hovered || latch.active）。
            // hover 命中范围受 rangeBox 的 containmentMask（rangeCrystal）
            // 限制——仅晶体内有效，区间盒空余处不触发。
            HoverHandler {
                id: hoverer
                enabled: root.enabled
            }

            // 前景尺寸动画（Qool 非可视组件）：from = 区间盒 − 收缩量（常态）、
            // to = 区间盒全尺寸（hover/值变化锁存展开）；resized =
            // hoverer.hovered || latch.active 驱动 from↔to 切换（动画门控
            // animationEnabled——关闭时跳变）；enabled 门控 resized 响应——
            // 禁用时前景冻结（与 hover/光标同受 root.enabled 控制）。
            ItemAnimatedResizer {
                id: cResizer
                enabled: root.enabled
                animationEnabled: root.animationEnabled

                fromWidth: rangeBox.width - pCtrl.shrinkSize
                fromHeight: rangeBox.height - pCtrl.shrinkSize

                toWidth: rangeBox.width
                toHeight: rangeBox.height

                resized: hoverer.hovered || latch.active
            }

            // 区间前景（Crystal 连体：左点 + 直边 + 右点、尖角外溢）——
            // 尺寸随 cResizer（hover 展开/常态收缩）、居中于区间盒。
            Crystal {
                id: rangeCrystal
                width: cResizer.width
                height: cResizer.height
                anchors.centerIn: parent
            }

            containmentMask: rangeCrystal
        }
    }//contentItem

}
