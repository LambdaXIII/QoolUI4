import QtQuick
import QtQuick.Templates as T
import Qool

// Slider：Qool.Controls 系列滑块（基座 T.Slider，官方 API 兼容——from/to/
// value/stepSize/live/snapMode 等照官方文档使用，行为契约官方默认全继承）。
//
// 定位：**裸控件**——无 QoolControl 壳（背景盒/标题/标签/内边距）、无 covers
// 三件套；壳由宿主包装 QoolControl（InputControls 家族与壳解耦是原则）。
//
// **无手柄设计**：交互 = 模板默认整框交互（点击跳转 + 拖动连续 + 键盘步进），
// 零自定义交互逻辑。handle 槽被**值显示件**占用——handle 官方语义是"随值
// 移动的视觉项"（delegate 自定位），填充+文字一体天然符合；宿主替换
// handle = 换整个值显示（含自定义数值格式）。
//
// 两视觉层（官方结构，各层独立可替换）：
//   - background = 纯壳：切角方框轨道（仅左上+右下切角、透明底 + 可见边框）
//     ——替换 = 换外壳（如不透明背景）
//   - handle = 值显示件：填充（accent、宽随 visualPosition）+ 数值文字
//     （双 Text 副本 + 裁剪容器同层分区着色——透明区段主题前景色、填充区段
//     按亮度计算对比色）——替换 = 换整个值显示
// contentItem 不定义（官方 Slider 样式同款，弃用——文字归 handle 不归壳）。
//
// 反馈（值显示件上的填充层）：
//   - hover（enabled）：光标 = SizeHorCursor（水平双向箭头），不变色——
//     由控件内 hover-only MouseArea 承载（cursorShape 是 MouseArea 属性，
//     QQuickItem::setCursor 未暴露 QML 属性；MouseArea NoButton 不拦截点击，
//     模板输入不受影响）
//   - pressed || TimerLatch.active：fillColor → lighter(accent, 1.4)
//     （v3 ChannelBar 同款系数），BasicColorBehavior 门控 Style.animationEnabled
//   - 程序化 value 变化与拖动同款反馈语言——TimerLatch 在控件层（pCtrl），
//     **组件内部对象**：宿主替换 handle 后不可见（自定反馈；官方状态
//     hovered/pressed/activeFocus 均为暴露接口可自行绑定，锁存语义可自行
//     实例化 TimerLatch）
//
// 契约（QDoc 后置，注释先行）：
//   - 行为默认值全部照官方（live=true/NoSnap/stepSize=0/点击跳转/键盘步进）
//   - 倒置范围 from>to：完整支持（模板自洽——映射/夹紧/拖动/键盘全按官方
//     语义，实测确认）；刻度反向：increase() 增大实际值、视觉向 to 端移动
//     ——**是刻度反向语义，非缺陷**；不覆写 increase/decrease
//   - v1 仅支持水平（orientation 垂直化预留——布局公式集中在 pCtrl 方向层，
//     改造只需调方向公式：轨道竖置/填充自下而上/文字另位/光标 SizeVerCursor/
//     切角镜像）
//   - 焦点视觉不内置（无 covers、无边框高亮）——宿主按需自行绑定
//     activeFocus（官方暴露接口，不默认绑定）
//   - value 显示格式内置：最多 3 位小数、不足去尾零去点（无格式化 API——
//     宿主自定义显示 = 替换 handle）

T.Slider {
    id: root

    implicitWidth: 200
    implicitHeight: root.Style.controlTitleTextSize + 12

    // —— 光标反馈（hover-only MouseArea）——
    // cursorShape 是 MouseArea 的属性（QQuickItem 的 setCursor 未暴露为 QML
    // 属性——Qt 6.11 文档 Properties 无 cursor）——以 hover-only MouseArea
    // 承载：acceptedButtons NoButton = 不拦截点击（模板输入不受影响）；
    // hoverEnabled 消费 hover 事件（模板 hovered 可能不更新——本控件视觉
    // 不依赖 hovered，光标状态直接用 containsMouse）。enabled 门控：禁用时
    // 无光标反馈
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: root.enabled && containsMouse ? Qt.SizeHorCursor
                                                   : Qt.ArrowCursor
    }//MouseArea

    // —— 视觉层 1：background（纯壳：切角方框轨道）——
    // 仅左上+右下切角（controlCutSize），透明底 + mid 边框；垂直居中于 root
    background: OctagonRoundedShape {
        z: 0
        width: parent.width
        height: pCtrl.trackHeight
        y: pCtrl.trackY
        settings {
            cutSizeTL: root.Style.controlCutSize
            cutSizeBR: root.Style.controlCutSize
            borderWidth: root.Style.controlBorderWidth
            borderColor: root.Style.mid
            fillColor: "transparent"
        }
    }//background

    // —— 视觉层 2：handle（值显示件：填充 + 数值文字）——
    // 固定区域 = root 全区域；内部：填充底、文字层顶（同层双 Text 分区着色）
    handle: Item {
        z: 1
        width: parent.width
        height: parent.height

        // 填充：accent，宽 = availableWidth × visualPosition（RTL 自动镜像）；
        // LTR 贴左、RTL 右端固定；右下切角随 value 悬浮（与轨道同款切角——
        // 切，value=100% 时与轨道融合）；borderWidth 与轨道同值（内部形状
        // 几何对齐）、borderColor 透明（无边框视觉，反馈走 fillColor）
        OctagonRoundedShape {
            id: fillShape
            width: pCtrl.fillWidth
            height: pCtrl.trackHeight
            x: pCtrl.fillX
            y: pCtrl.trackY
            settings {
                cutSizeTL: root.Style.controlCutSize
                cutSizeBR: root.Style.controlCutSize
                borderWidth: root.Style.controlBorderWidth
                borderColor: "transparent"
                // 反馈（决策注释——§8 验证点"disabled 时程序化 value 变化
                // 是否触发锁存提亮"）：disabled 不抑制 NumberNotifier 采样，
                // 程序化写入仍提亮（v3 ChannelBar 无 enabled 概念，同款语义
                // ——故意保持：锁存反馈是"值运动"语义，与交互状态无关；
                // 宿主不想要可替换 handle 自定）
                fillColor: root.pressed || pCtrl.latch.active
                           ? Qt.lighter(root.Style.accent, 1.4)
                           : root.Style.accent
            }
            BasicColorBehavior on settings.fillColor {
                enabled: root.Style.animationEnabled
            }
        }//fillShape

        // 文字层（同层——两个 Text 副本 + 两个裁剪容器都在 handle 内，
        // 无跨层引用）：容器按填充边界（fillShape.width）分区裁剪；
        // 两 Text 右对齐同位置叠放——边界扫过文字时两段颜色自然切换
        // 容器 B：填充区段（左段，宽 = fillW）
        Item {
            id: fillTextClip
            width: pCtrl.fillWidth
            height: parent.height
            clip: true
            Text {
                id: textB
                text: pCtrl.displayText
                font.pixelSize: root.Style.controlTitleTextSize
                color: ThemeDB.recommendForeground(root.Style.accent)
                x: root.width - width - 6
                y: (parent.height - height) / 2
            }//textB
        }//fillTextClip
        // 容器 A：透明区段（右段，x = fillW）
        Item {
            id: gapTextClip
            x: pCtrl.fillWidth
            width: parent.width - pCtrl.fillWidth
            height: parent.height
            clip: true
            Text {
                id: textA
                text: pCtrl.displayText
                font.pixelSize: root.Style.controlTitleTextSize
                color: root.Style.text
                x: root.width - width - 6 - pCtrl.fillWidth
                y: (parent.height - height) / 2
            }//textA
        }//gapTextClip
    }//handle

    // —— 顶层观测（root 直接子项——on 语法修饰 root.value）——
    NumberNotifier on value {
        id: notifier
    }

    // —— 逻辑对象：值运动反馈机制（控件层）——
    // 方向层（垂直化改造点）：v1 仅水平——**方向敏感的核心量集中于此**
    // （轨道高/垂直居中 y/填充宽与 x），delegate 绑定本组只读属性；
    // 文字层定位在 handle 内绑定 fillWidth 等量（其 x 依赖 Text 自身
    // implicitWidth，见 handle）。垂直化改造：改本组公式（轨道竖置/
    // 填充自下而上/文字另位/光标 SizeVerCursor/切角镜像）——v1 仅水平契约
    SmartObject {
        id: pCtrl

        readonly property string displayText: format_value(root.value)

        // 方向层核心量（水平布局公式——见上注释）
        readonly property real trackHeight: 6
        readonly property real trackY: (root.height - trackHeight) / 2
        readonly property real fillWidth: root.availableWidth
                                          * root.visualPosition
        readonly property real fillX: root.mirrored
                                      ? root.width - fillWidth : 0

        function format_value(v) {
            return Number(v.toFixed(3)).toString()
        }

        TimerLatch {
            id: latch
            interval: 1000
        }

        Connections {
            target: notifier
            function onValueUpdated() {
                latch.activate()
            }
        }
    }//pCtrl
}
