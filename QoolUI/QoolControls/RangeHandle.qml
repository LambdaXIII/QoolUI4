// Qool.Controls.RangeHandle：区间滑块的范围交互件（与 RangeSlider 配套，
// 可独立实例化）——三区域拖动、热区扩展、光标形状的单一归属；除 surface
// （纯外观）外一切行为止于此。宿主可继承本组件并替换到 RangeSlider 的
// rangeHandle 属性实现行为插拔。
//
// 三区域交互：左端区拖动 → wannaMoveFirstX、右端区拖动 →
// wannaMoveSecondX、中段区拖动 → wannaMoveRangeX（载荷均为像素增量位移，
// 相对上次事件）；全部点击无操作。三区物理分区（左/右端点热区 +
// 中段行程区），基于本组件几何推导（height 为手柄基准），与 surface
// 尺寸无关——展开/常态下分区稳定一致。
//
// 本组件不收位置输入、不发结果位置：值→位置映射、位移→值换算、端点
// 钳制全部在宿主（RangeSlider 有 leftPadding/availableWidth 行程公式）。
// surface 仅设 parent，布局由 surface 自行负责（默认实例 anchors.fill）。
//
// 完整契约（布局/插拔/交互/几何）见
// docs/reference/Qool.Controls/RangeHandle.md。

import QtQuick
import Qool

Item {
    id: root

    /* surface（外观插拔件）：默认占位矩形。布局由 surface 自行负责
       （默认 anchors.fill 本组件；宿主替换任意 Item 同样须自行布局——
       RangeHandle 不再施加布局）。surface 不自行响应值数据。 */
    property Item surface: Rectangle {
        anchors.fill: parent
        border.width: 1
        border.color: Style.buttonText
        color: Style.accent
    }

    property real firstMouseZoneExtension: 2
    property real secondMouseZoneExtension: firstMouseZoneExtension

    readonly property bool down: centerMouseArea.pressed || leftMouseArea.pressed || rightMouseArea.pressed
    // 三区任一悬停（宿主 surface 展开反馈可用——与 down 同型聚合）
    readonly property bool hovered: centerMouseArea.hovered || leftMouseArea.hovered || rightMouseArea.hovered

    property alias firstCursorShape: leftMouseArea.cursorShape
    property alias secondCursorShape: rightMouseArea.cursorShape

    signal wannaMoveFirstX(real x)
    signal wannaMoveSecondX(real x)
    signal wannaMoveRangeX(real x)

    SmartObject {
        id: pCtrl
        readonly property real rangeHSpace: Math.max(0, root.width - root.height)
        readonly property real handleHSpace: Qore.bound(0, root.height / 2, root.width / 2)
        Binding {
            when: root.surface
            target: root.surface
            property: "parent"
            value: root
        }
    }

    DragMoveArea {
        id: centerMouseArea
        // autoBind 默认 true：拖动会移动 target（parent=本组件）——与
        // 宿主（dummyRangeBox Binding）对 rangeHandle 几何的声明式控制
        // 双重驱动（位置错乱）。几何只应经值→位置映射生效，显式关闭。
        autoBind: false
        width: pCtrl.rangeHSpace
        height: root.height
        x: (root.width - width) / 2
        y: 0
        enabled: root.enabled && width > 0
        hoverEnabled: true
        cursorShape: Qt.SizeHorCursor
        onWannaMove: (x, _) => root.wannaMoveRangeX(x)
    }

    DragMoveArea {
        id: leftMouseArea
        autoBind: false // 同 center——几何只应经值→位置映射生效（见 center 注释）
        width: pCtrl.handleHSpace + root.firstMouseZoneExtension
        height: root.height
        x: 0 - root.firstMouseZoneExtension
        y: 0
        enabled: root.enabled && width > 0
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        onWannaMove: (x, _) => root.wannaMoveFirstX(x)
    }

    DragMoveArea {
        id: rightMouseArea
        autoBind: false // 同 center——几何只应经值→位置映射生效（见 center 注释）
        width: pCtrl.handleHSpace + root.secondMouseZoneExtension
        height: root.height
        x: root.width - pCtrl.handleHSpace
        y: 0
        enabled: root.enabled && width > 0
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        onWannaMove: (x, _) => root.wannaMoveSecondX(x)
    }
} //Item
