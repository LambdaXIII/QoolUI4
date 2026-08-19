// Qool.Controls.RangeSlider：三层结构区间滑块（T.RangeSlider 模板 API
// 兼容）——静态 Crystal 轨道 + RangeHandle（区间逻辑，行为插拔件）+
// surface（默认 Crystal 前景，外观插拔件，经 rangeHandle.surface 访问）。
//
// 完整契约（三层职责/三区域交互/插拔）见
// docs/reference/Qool.Controls/RangeSlider.md。

import QtQuick
import QtQuick.Templates as T
import Qool

T.RangeSlider {
    id: root
    // 前景填充色（surface 色——配套绑定到 rangeHandle.color），默认
    // Style.accent。
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

    // 行为插拔件：区间交互件（默认内部实例；宿主继承 RangeHandle 替换——
    // 覆盖行为即插拔；几何经 dummyRangeBox Binding 组施加、信号换算经
    // Connections 连接，替换后同样生效）。
    property RangeHandle rangeHandle: RangeHandle {
        firstMouseZoneExtension: height / 2
        surface: Item {
            anchors.fill: parent
            readonly property bool expanded: root.firstJustMoved || root.secondJustMoved || parent.down || parent.hovered
            Crystal {
                anchors.centerIn: parent
                // 额外宽度（尖角外溢）：切角 = min(w,h)/2 = h/2（w >= h）——
                // 宽 = 区间宽 + height：直边区 = w − h = 区间宽（恒等——收缩
                // 只体现在高度维度）、尖点外溢 h/2（随高度变）。区间宽
                // （parent.width）实时——拖动手柄/值变化时宽度即时跟手，不
                // 动画；height 项随展开动画平滑（放大/收缩动态）
                width: parent.width + height
                height: parent.height - (parent.expanded ? 0 : pCtrl.crystalShrinkSize)
                // 展开/收缩反馈动画（同 Slider 手柄）：仅 height——width 含
                // 实时区间宽分量（Behavior 会拦截每次值变化致拖动不跟手），
                // 由 height 项随动画联动（放大/收缩动态、区间宽实时跟手）
                BasicNumberBehavior on height {
                    enabled: root.animationEnabled
                    duration: Style.transitionDuration
                }
                color: root.color
                borderColor: root.borderColor
            }
        }
    } //defaultRangeHandle

    // 尺寸：反向排版策略（Slider 同款）——模板不自带 implicit 公式，root 直接
    // 给默认尺寸（80 × 25），background 基于 root 布局
    implicitWidth: 80
    implicitHeight: 25

    SmartObject {
        id: pCtrl
        // 常态收缩量：轨道高度与前景高度从全尺寸收缩的量（展开时前景占满
        // 区间盒）——轨道恒为常态（静态，不参与交互反馈），前景随 expanded
        // 切换收缩/占满。
        readonly property real crystalShrinkSize: Qore.bound(3, root.height * 0.25, 25)
        // 像素位移 → 值增量（1px = 全值域 / 内容区宽——dummyRangeBox 位置
        // 公式 x = availableWidth * position + leftPadding 的逆映射）
        function pixelToValueDelta(dx) {
            const travel = root.availableWidth;
            if (travel <= 0)
                return 0;
            return dx / travel * (root.to - root.from);
        }

        // background 显式控尺寸（root.width − insets——Control 默认自动 fill
        // 控件；此处显式声明保证与 inset 对齐语义稳定，供轨道尖角外溢定位）
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

    // —— 区间盒（值→位置映射的唯一落点）：x/y/width/height 即 rangeHandle
    // 几何（RangeHandle 只收几何、不收位置值）；Binding 组动态施加——
    // 宿主替换 rangeHandle 时新实例同样受控。parent 显式挂（属性对象不
    // 自动成为声明对象的子项——宿主内联替换实例亦须置入控件坐标空间）
    DummyItem {
        id: dummyRangeBox
        x: root.availableWidth * root.first.position + root.leftPadding
        y: 0 + root.topPadding
        width: root.availableWidth * (root.second.position - root.first.position)
        height: root.height - root.topPadding - root.bottomPadding

        Binding {
            when: root.rangeHandle
            target: root.rangeHandle
            property: "parent"
            value: root
        }
        Binding {
            when: root.rangeHandle
            target: root.rangeHandle
            property: "x"
            value: dummyRangeBox.x
        }
        Binding {
            when: root.rangeHandle
            target: root.rangeHandle
            property: "y"
            value: dummyRangeBox.y
        }
        Binding {
            when: root.rangeHandle
            target: root.rangeHandle
            property: "width"
            value: dummyRangeBox.width
        }
        Binding {
            when: root.rangeHandle
            target: root.rangeHandle
            property: "height"
            value: dummyRangeBox.height
        }
    }

    // 信号换算（target 动态——替换实例同样连接）：位移增量 → 值写入。
    // 端点钳制在值域侧（first ∈ [from, second]、second ∈ [first, to]，
    // 模板保证 second >= first——区间恒正向）；整体滑移按区间整体钳制
    // （两端同移、区间宽不变、边界整体停）。
    Connections {
        target: root.rangeHandle
        function onWannaMoveFirstX(dx) {
            const v = root.first.value + pCtrl.pixelToValueDelta(dx);
            root.setValues(Math.max(root.from, Math.min(v, root.second.value)), root.second.value);
        }
        function onWannaMoveSecondX(dx) {
            const v = root.second.value + pCtrl.pixelToValueDelta(dx);
            root.setValues(root.first.value, Math.min(root.to, Math.max(v, root.first.value)));
        }
        function onWannaMoveRangeX(dx) {
            const deltaV = pCtrl.pixelToValueDelta(dx);
            const shift = Math.max(root.from - root.first.value, Math.min(root.to - root.second.value, deltaV));
            root.setValues(root.first.value + shift, root.second.value + shift);
        }
    }
} //T.RangeSlider
