// Qool.Controls.RangeSlider：区间滑块（水平/垂直 + RTL，T.RangeSlider 模板
// API 兼容；orientation×RTL 正交统一见 ADR-0011，同 Slider 的 0010 模式）。
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
    // 配色模型（统一样式接口——控件不设实例色属性，同 Slider）：轨道 =
    // Style.buttonText（名字兼容 Qt palette，实际语义是 control 前景色）
    // 75% 透明 + ThemeHQ.recommendForeground(Style.buttonText) 描边；
    // 前景 rangeCrystal = Style.accent——control 前景 → accent 对照着色。
    // 宿主换色经 Style 附着传播（挂本实例或任意祖先，粒度单实例到全局）。
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 尺寸：反向排版策略——模板自带 implicit 公式（background 与 contentItem
    // 的 implicit 尺寸取大者）；组件只给 background 显式 implicit（150×25），
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
        // 法向尺寸抽象：轨道/前景/窄条的法向尺寸——水平时 = 可用高、
        // 垂直时 = 可用宽（同 Slider）。横竖对称、镜像无关；收缩量/轨道
        // 收缩/前景收缩/窄条换向全部基于它。
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        // 常态收缩量：轨道与前景从全尺寸收缩的量（hover 展开时前景占满
        // 区间盒；轨道恒为常态——静态，不参与交互反馈）。
        readonly property real shrinkSize: Qore.bound(3, side * 0.25, 25)
        // 收缩偏移量的一半——轨道沿法向居中（收缩后两端各留 shrinkSize/2）。
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    // 轨道层：Crystal 六边形（backgroundColor 75% 透明 + borderColor
    // 描边）——沿主轴铺满、恒为法向常态（不随交互变）+ 沿法向居中（y =
    // 收缩偏移/2 水平、x = 收缩偏移/2 垂直）。background 显式 implicit
    // （150×25，垂直 25×150）供控件 implicit 计算。
    background: Item {
        // implicit 随 orientation 交换（水平 150×25 ↔ 垂直 25×150）——对齐
        // 官方"垂直默认窄"惯例；根 implicit 公式本身不变（background 项
        // implicit 自适应）
        implicitHeight: root.horizontal ? 25 : 150
        implicitWidth: root.horizontal ? 150 : 25

        Crystal {
            // 焦点高亮：键盘聚焦（visualFocus——仅 Tab/Backtab/Shortcut 键盘
            // 原因聚焦）时边框切换 Style.highlight、失焦恢复
            // ThemeHQ.recommendForeground(Style.buttonText)（自动对比推荐）
            borderColor: root.visualFocus ? root.Style.highlight : ThemeHQ.recommendForeground(root.Style.buttonText)
            // 切换动画门控 animationEnabled（关闭时即时跳变）
            BasicColorBehavior on borderColor {
                enabled: root.animationEnabled
            }
            color: Qt.alpha(root.Style.buttonText, 0.75)
            // 轨道沿主轴铺满（尖点贴边不外溢）、沿法向常态收缩 + 居中
            // （水平收缩高、垂直收缩宽）——法向居中不随镜像变化
            width: root.horizontal ? parent.width : parent.width - pCtrl.shrinkSize
            height: root.horizontal ? parent.height - pCtrl.shrinkSize : parent.height
            x: root.horizontal ? 0 : pCtrl.halfShrinkSpace
            y: root.horizontal ? pCtrl.halfShrinkSpace : 0
        }
    }

    // —— 默认透明 handle（模板 handle 插拔点：宿主替换即自定义端点命中/
    // 视觉/光标）：窄条随轴换向（水平竖条宽 = 高/2、垂直横条高 = 宽/2，法向
    // 满、主轴厚 = 法向/2）——视觉由前景 rangeCrystal 承担，handle 只做模板
    // 拖动/键盘的命中基准。
    //
    // 不相交公式随轴换：水平行程 = availableWidth − width×2（扣除两个 handle
    // 的宽）、垂直行程 = availableHeight − height×2——first 从 0 起、second
    // 从 width/height 起，两 handle 各自占侧、任意值下永不相交（端点重合时
    // 相邻不重叠）。用 visualPosition（RTL/垂直时反向）而非 position，与
    // 模板一致。法向居中于可用区；z:10 保证盖在 contentItem 前景之上、拖动
    // 命中不受前景遮挡。
    first.handle: Item {
        // 窄条换向：水平竖条（w = side/2、h = side）↔ 垂直横条（w = side、
        // h = side/2——法向满、主轴厚 = 法向/2）
        width: root.horizontal ? pCtrl.side / 2 : pCtrl.side
        height: root.horizontal ? pCtrl.side : pCtrl.side / 2
        // 定位双分支（handle delegate 须自写定位——模板不注入，官方双分支
        // 完整公式含 padding）：水平 x 由 visualPosition（RTL 镜像）驱动、
        // y 居中；垂直 y 由 visualPosition 驱动、x 居中。不相交公式随轴换
        // （水平行程 = availableWidth − w×2、垂直 = availableHeight − h×2——
        // 两 handle 各自占侧、任意值不相交）。RTL 由模板免费承载（vertical +
        // RTL 时 visualPosition 仍反转，跟随 Qt 模板语义——不特判）
        x: root.horizontal ? root.leftPadding + root.first.visualPosition * (root.availableWidth - width * 2)
                           : root.leftPadding + root.availableWidth / 2 - width / 2
        y: root.horizontal ? root.topPadding + root.availableHeight / 2 - height / 2
                           : root.topPadding + root.first.visualPosition * (root.availableHeight - height * 2)
        z: 10

        MouseArea {
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
            acceptedButtons: Qt.NoButton
            anchors.fill: parent
        }
    }

    second.handle: Item {
        // 窄条换向（同 first）；second 起步偏移随轴换：水平 + width（从
        // first 宽处起步）、垂直 + height（从 first 高处起步）
        width: root.horizontal ? pCtrl.side / 2 : pCtrl.side
        height: root.horizontal ? pCtrl.side : pCtrl.side / 2
        x: root.horizontal ? root.leftPadding + width + root.second.visualPosition * (root.availableWidth - width * 2)
                           : root.leftPadding + root.availableWidth / 2 - width / 2
        y: root.horizontal ? root.topPadding + root.availableHeight / 2 - height / 2
                           : root.topPadding + height + root.second.visualPosition * (root.availableHeight - height * 2)
        z: 10

        MouseArea {
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
            acceptedButtons: Qt.NoButton
            anchors.fill: parent
        }
    }

    // —— 前景层（contentItem 内）：rangeBox 区间盒承载——主轴（水平 x /
    // 垂直 y）起点 = min(first.vP, second.vP) × 行程、跨度 = |second.vP −
    // first.vP| × 行程 + 尖角余量（水平 = 自身高、垂直 = 自身宽，多出余量
    // 作尖角外溢/对齐）；法向满宽/满高 + 居中。
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
            // 区间盒跨轴统一：主轴（水平 x / 垂直 y）起点 = min(first.vP,
            // second.vP) × 行程、跨度 = |second.vP − first.vP| × 行程 + 尖角
            // 余量（水平 = 自身高、垂直 = 自身宽）——vP 差在垂直/RTL 为负，
            // 故 abs（区间大小镜像无关）；法向满宽/满高 + 居中。LTR 水平下
            // min/abs 数学等价既有公式（不破水平行为）。Crystal 连体尖角外溢
            // 余量随轴换：水平 = height、垂直 = width（切角 = 短边/2）
            x: root.horizontal ? Math.min(root.first.visualPosition, root.second.visualPosition) * (parent.width - height)
                               : parent.width / 2 - width / 2
            y: root.horizontal ? parent.height / 2 - height / 2
                               : Math.min(root.first.visualPosition, root.second.visualPosition) * (parent.height - width)
            width: root.horizontal ? (parent.width - height) * Math.abs(root.second.visualPosition - root.first.visualPosition) + height
                                   : parent.width
            height: root.horizontal ? parent.height
                                    : (parent.height - width) * Math.abs(root.second.visualPosition - root.first.visualPosition) + width

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
                // 前景填充色 = Style.accent（统一样式接口——换色经 Style 附着
                // 传播，宿主不设实例色属性）
                color: root.Style.accent
                width: cResizer.width
                height: cResizer.height
                anchors.centerIn: parent
            }

            containmentMask: rangeCrystal
        }
    }//contentItem

}
