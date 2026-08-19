// Qool.Controls.RangeSlider：区间滑块（T.RangeSlider 模板 API 兼容）——
// 模板 handle 体系（默认透明 handle 激活模板交互——snap/live/键盘/
// nearest/端点钳制免费）+ 静态 Crystal 轨道 + surface（默认 Crystal 连体
// 前景，外观插拔件，root 直接属性）。
//
// 完整契约（双端点交互/插拔/snap-live 语义/几何模型）见
// docs/reference/Qool.Controls/RangeSlider.md。

import QtQuick
import QtQuick.Templates as T
import Qool

T.RangeSlider {
    id: root
    // 前景填充色（surface 色），默认 Style.accent。
    property color color: Style.accent
    // 轨道背景色（track 以 75% 透明度渲染），默认 Style.buttonText。
    property color backgroundColor: Style.buttonText
    // 前景/轨道描边色——基于 backgroundColor 自动对比推荐（宿主可单独覆盖）。
    property color borderColor: ThemeHQ.recommendForeground(backgroundColor)
    // "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）；
    // 两端独立——写入哪端锁存哪端，互不影响。
    property bool firstJustMoved: firstMovementLatch.active
    property bool secondJustMoved: secondMovementLatch.active
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 外观插拔件：区间前景（默认 Crystal 连体前景——左点 + 直边 + 右点、
    // 尖角外溢、常态收缩/展开占满）。几何（x/y/width/height = 区间盒——
    // 值→位置映射的唯一落点）经 dummyRangeBox Binding 组动态施加——宿主
    // 替换 surface 时新实例同样受控：填满区间盒即得精确区间，无需自算映射。
    property Item surface: Item {
        // 展开条件：任一锁存（值刚写入）或端点按压/悬停（模板 handle 状态）
        readonly property bool expanded: root.firstJustMoved || root.secondJustMoved
            || root.first.pressed || root.first.hovered
            || root.second.pressed || root.second.hovered
        Crystal {
            anchors.centerIn: parent
            // 尖角外溢几何（同轨道）：直边区 = 区间宽（parent.width 实时——
            // 值变化即时跟手不动画）、尖点外溢 h/2（随高度变）；height 随
            // 展开动画平滑（放大/收缩动态）
            width: parent.width + height
            height: parent.height - (parent.expanded ? 0 : pCtrl.crystalShrinkSize)
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            color: root.color
            borderColor: root.borderColor
        }
    }

    // 尺寸：反向排版策略（Slider 同款）——模板不自带 implicit 公式，root
    // 直接给默认尺寸（80 × 25），background 基于 root 布局
    implicitWidth: 80
    implicitHeight: 25

    // —— 默认透明 handle（行为插拔点：宿主替换 first/second handle 即
    // 自定义端点命中/视觉/光标——模板 handle 插拔契约）：透明（视觉由
    // surface 承担）、矩形命中（contains 即热区）、中心对齐值位置——
    // handle 中心 = surface 端点（几何同源）；拖动映射经模板 positionAt
    // offset = hw/2 自洽（按住中心精确跟手，按住边缘偏移 hw/2——模板
    // 固有模型，同 Slider 手柄）——
    first.handle: Item {
        width: root.availableHeight
        height: root.availableHeight
        x: root.leftPadding + root.availableWidth * root.first.position - width / 2
        y: root.topPadding
        // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动经 handle 命中
        // 有效——同 Slider 手柄）；disabled 时无反馈
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: Qt.SplitHCursor
        }
    }
    second.handle: Item {
        width: root.availableHeight
        height: root.availableHeight
        x: root.leftPadding + root.availableWidth * root.second.position - width / 2
        y: root.topPadding
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: Qt.SplitHCursor
        }
    }

    SmartObject {
        id: pCtrl
        // 常态收缩量：轨道高度与前景高度从全尺寸收缩的量（展开时前景占满
        // 区间盒）——轨道恒为常态（静态，不参与交互反馈），前景随 expanded
        // 切换收缩/占满。
        readonly property real crystalShrinkSize: Qore.bound(3, root.height * 0.25, 25)

        // background 显式控尺寸（root.width − insets——Control 默认自动
        // fill 控件；此处显式声明保证与 inset 对齐语义稳定，供轨道尖角外溢
        // 定位。外部 Binding 施加：宿主替换 background 时新实例同样受控，
        // 插拔安全）
        Binding {
            target: root.background
            when: root.background
            property: "width"
            value: root.width - root.leftInset - root.rightInset
        }

        Binding {
            target: root.background
            when: root.background
            property: "height"
            value: root.height - root.topInset - root.bottomInset
        }
    }

    // —— 轨道层（Item 容器——background 由 pCtrl Binding 控尺寸，内部坐标
    // = root 本地）：静态 Crystal 六边形（backgroundColor 75% 透明度 +
    // borderColor 描边）——恒为常态高度 + 垂直居中（三心对齐）；不参与交
    // 互反馈（视觉焦点在前景）
    background: Item {
        //包装一层是为了和padding对齐
        Crystal {
            id: track
            objectName: "track" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外——轨道静态性是公开视觉契约）
            // 同前景尖角外溢几何：额外宽度（尖点外溢 h/2、直边区 = 控件宽）、
            // 恒常态高度（静态——不参与交互反馈）
            width: parent.width + height
            height: parent.height - pCtrl.crystalShrinkSize
            anchors.centerIn: parent //居中锚点保证Crystal图形合理化后不偏移
            color: Qt.alpha(root.backgroundColor, 0.75)
            borderColor: root.borderColor
        } //track
    } //background

    TimerLatch {
        id: firstMovementLatch
        interval: 500
        Connections {
            target: root.first
            function onValueChanged() {
                firstMovementLatch.trigger();
            }
        }
    }
    TimerLatch {
        id: secondMovementLatch
        interval: 500
        Connections {
            target: root.second
            function onValueChanged() {
                secondMovementLatch.trigger();
            }
        }
    }

    // —— 区间盒（值→位置映射的唯一落点）：surface 几何（x/y/width/height =
    // 区间盒）；Binding 组动态施加——宿主替换 surface 时新实例同样受控。
    // parent 显式挂 contentItem（属性对象不自动成为声明对象的子项——宿主
    // 内联替换实例亦须置入控件坐标空间）
    DummyItem {
        id: dummyRangeBox
        x: root.availableWidth * root.first.position + root.leftPadding
        y: 0 + root.topPadding
        width: root.availableWidth * (root.second.position - root.first.position)
        height: root.height - root.topPadding - root.bottomPadding

        Binding {
            when: root.surface
            target: root.surface
            property: "parent"
            value: root.contentItem
        }
        Binding {
            when: root.surface
            target: root.surface
            property: "x"
            value: dummyRangeBox.x
        }
        Binding {
            when: root.surface
            target: root.surface
            property: "y"
            value: dummyRangeBox.y
        }
        Binding {
            when: root.surface
            target: root.surface
            property: "width"
            value: dummyRangeBox.width
        }
        Binding {
            when: root.surface
            target: root.surface
            property: "height"
            value: dummyRangeBox.height
        }
    }
} //T.RangeSlider
