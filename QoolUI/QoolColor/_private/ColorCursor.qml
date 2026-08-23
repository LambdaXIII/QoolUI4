// ColorCursor：HSV/HSL 两表面共用的组合取色光标（Qool.Color/_private）。
//
// 定位：值位置 = 光标中心点（消费方经 surface.position(...) 映射派生，
// 非被拖动对象）；组合 CrystalCursor（延迟缩放 + Crystal 自带菱形
// contains 命中域）+ CenterPlacer（center ↔ x/y 双向）+ TimerLatch
// （值变化锁存归约）。
//
// 易误解点（勿改）：
// - **禁止用 QML 绑定写 centerx/centery**——CenterPlacer 的 onXChanged
//   显式回写会替换绑定（QML 显式赋值破坏绑定），光标将冻结；消费方必须
//   事件驱动赋值（assistant 通道信号触发 + 显式赋值）。
// - 命中域：内部 Crystal 锚定根中心（缩放展开中心不动）——其自带 contains
//   域与旧 Crystal4ContainmentMask 语义等价（菱形外按压贯通）。
// - 锁存触发源从旧 latchTarget（assistant 全通道，含 value）改为 center
//   变化（center 变化 = 位置变化 = 表面值变化）；value 通道不再触发——
//   value 不移动光标，视觉差异可接受（ADR-0016 去 latchTarget 的必然结果）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Controls.Components

Item {
    id: root

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    // 声明序首位（AGENTS MUST——统一声明序）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 光标实色（消费方注入，如表面 solidColor）。
    property color currentColor: "white"
    // 交互态（消费方转发 InteractingArea）——三态展开输入之一。
    property bool expanded: false
    // 组件边长（根 footprint = size × size）。
    property real size: 20
    // 展开增量（对齐旧 HSVWheelCursor：常态 = size、展开 = size + expandDelta）。
    readonly property real expandDelta: Qore.bound(4, root.size * 0.35, 15)

    width: size
    height: size

    // 中心坐标：alias 到 CenterPlacer（读 = x + width/2、写 = 代理设 x/y）。
    // 消费方只许事件驱动赋值（见文件头易误解点）。
    property alias centerx: placer.centerx
    property alias centery: placer.centery

    CenterPlacer {
        id: placer
        target: root
    }

    // 组合基准件：根 = size + expandDelta（fullSize 角色）、delta = expandDelta
    // → 常态 Crystal = size、展开 = size + expandDelta（旧 HSVWheelCursor 视觉
    // 逐点等价）；anchors.centerIn 保证 Crystal 中心 = 根中心 = center 位置
    //（命中域与旧掩码语义等价）。
    CrystalCursor {
        id: base
        objectName: "baseCursor" // 测试定位（组件内部对象零暴露原则的测试例外）
        enabled: root.enabled
        width: root.size + root.expandDelta
        height: root.size + root.expandDelta
        anchors.centerIn: root
        delta: root.expandDelta
        animationEnabled: root.animationEnabled
        color: root.currentColor
        expanded: root.expanded
    }
}
