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
    property color color: root.Style.accent
    // "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。
    property bool justMoved: movementLatch.active
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 常态高度：轨道与 surface 的常态（收缩）高度——展开时 surface 占满
    // 控件全高（root.height）。
    readonly property real preferredHeight: root.height - Qore.bound(3, root.height * 0.25, 25)
    // 行为插拔件：区间逻辑容器（默认内部实例；宿主继承 RangeHandle 替换——
    // 覆盖行为即插拔；配套绑定统一经下方 Binding 组施加，替换后同样生效）。
    property RangeHandle rangeHandle: defaultRangeHandle

    // 尺寸：反向排版策略（Slider 同款）——模板不自带 implicit 公式，root 直接
    // 给默认尺寸（80 × 25），background 基于 root 布局
    implicitWidth: 80
    implicitHeight: 25

    // —— 端点位置（父级坐标——值→位置映射，RangeSlider 职责；RangeHandle
    // 不复制模板行程语义）——
    readonly property real firstPosition: root.leftPadding + root.first.visualPosition * (root.availableWidth - root.height) + root.height / 2
    readonly property real secondPosition: root.leftPadding + root.second.visualPosition * (root.availableWidth - root.height) + root.height / 2

    // 位置→值换算（RangeHandle 信号载荷的逆映射——与正向公式互逆；模板
    // 保证 first.visualPosition <= second.visualPosition——区间恒正向）
    function positionToValue(pos) {
        const travel = root.availableWidth - root.height
        if (travel <= 0)
            return root.from
        const p = (pos - root.leftPadding - root.height / 2) / travel
        return root.from + p * (root.to - root.from)
    }

    // 整体滑移：位移 → 值增量，first/second 同步平移、区间宽不变、边界
    // 钳制整体停（setValues 写入——两端都停、区间宽不变）
    function shiftRange(delta) {
        const travel = root.availableWidth - root.height
        if (travel <= 0)
            return
        const valueDelta = delta / travel * (root.to - root.from)
        const shift = Math.max(root.from - root.first.value,
                               Math.min(root.to - root.second.value, valueDelta))
        root.setValues(root.first.value + shift, root.second.value + shift)
    }

    // —— 逻辑件：程序化变更锁存（TimerLatch——双值触发；Slider 的
    // NumberNotifier 挂单一 value 无对应载体，justMoved 窗口由每次
    // valueChanged 滑动保持）——
    TimerLatch {
        id: movementLatch
        interval: 500
        Connections {
            target: root.first
            function onValueChanged() {
                movementLatch.trigger();
            }
        }
        Connections {
            target: root.second
            function onValueChanged() {
                movementLatch.trigger();
            }
        }
    }

    // —— 轨道层（Item 容器——background 自动 fill 控件，内部坐标 = root
    // 本地）：静态 Crystal 六边形（Style.text 1 色非渐变）——恒为常态高度
    // + 垂直居中（三心对齐）；不参与交互反馈（视觉焦点在前景）
    background: Item {
        Crystal {
            id: track
            objectName: "track" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外——轨道静态性是公开视觉契约）
            width: root.width
            height: root.preferredHeight
            y: (root.height - height) / 2
            color: root.Style.text
        } //track
    } //background

    // —— 内置 RangeHandle（默认实例——宿主替换即行为插拔；配套绑定与
    // 信号换算统一在下方组内动态施加）——
    RangeHandle {
        id: defaultRangeHandle
        parent: root
    } //defaultRangeHandle

    // 配套绑定（target 为绑定表达式——宿主替换 rangeHandle 时新实例同样
    // 受控；值→位置映射在 root——RangeHandle 只收位置）。parent 显式挂
    // （属性对象不自动成为声明对象的子项——宿主内联替换实例亦须置入控件
    // 坐标空间）
    Binding {
        target: root.rangeHandle
        property: "parent"
        value: root
    }
    Binding {
        target: root.rangeHandle
        property: "width"
        value: root.width
    }
    Binding {
        target: root.rangeHandle
        property: "height"
        value: root.height
    }
    Binding {
        target: root.rangeHandle
        property: "firstPosition"
        value: root.firstPosition
    }
    Binding {
        target: root.rangeHandle
        property: "secondPosition"
        value: root.secondPosition
    }
    Binding {
        target: root.rangeHandle
        property: "cutSize"
        value: root.preferredHeight / 2
    }
    Binding {
        target: root.rangeHandle
        property: "preferredHeight"
        value: root.preferredHeight
    }
    Binding {
        target: root.rangeHandle
        property: "externalExpanded"
        value: root.justMoved
    }
    Binding {
        target: root.rangeHandle
        property: "animationEnabled"
        value: root.animationEnabled
    }
    Binding {
        target: root.rangeHandle
        property: "color"
        value: root.color
    }

    // 信号换算（target 动态——替换实例同样连接）：位置/位移 → 值写入
    Connections {
        target: root.rangeHandle
        function onFirstMoved(pos) {
            root.setValues(root.positionToValue(pos), root.second.value);
        }
        function onSecondMoved(pos) {
            root.setValues(root.first.value, root.positionToValue(pos));
        }
        function onRangeMoved(delta) {
            root.shiftRange(delta);
        }
    }
} //T.RangeSlider
