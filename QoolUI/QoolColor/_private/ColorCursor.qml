// NOTE(迁移) v3 Qool.Color/_private/ColorCursor.qml 逐字迁移。
// Style 对位：highlightColor → root.Style.highlight（默认值）、
// recommendedForegroundColor(color)（Style 函数）→ ThemeHQ.recommendForeground(color)
// （v4 语义近似：阈值 0.4→0.6，见 T13 对照表；light/dark 取默认白/黑）。
//
// 关键行为与易误解点（勿改）：
//   - centerx/centery ↔ x/y 双向同步（两个 Connections）：onXChanged 带守卫
//     （相同值不写回 centerx），onCenterxChanged 无条件写 x（含 v3 注释掉的
//     `if (root.x - v == 0)` 守卫）——两处不对称是 v3 原样，消费方要么绑定
//     x/y（ColorSlider：x 由 displayValue 绑定驱动），要么绑定 centerx/centery
//     （HSVWheel/HSLBox），两种用法都依赖这套同步。
//   - hoveredSize = size + limitNumber(size * 0.25, 15, 45)；states 中
//     悬停（hoverer.hovered）/ 交互（userInteracting）/ 刚移动（movementTimer
//     justMoved，1000ms 内）任一成立即展开到 hoveredSize。
//   - pControl.animationEnabled 额外要求 pControl.initialized（Component.onCompleted
//     置位）：组件创建时对默认值不做动画，之后才启用——v3 刻意延迟一帧。
//   - crystal（ColorCrystal）以 parent 中心定位（菱形中心 = 组件中心，见
//     ColorCrystal 头注释）；大小/填充/描边动画都经 pControl.animationEnabled 门控。
//   - containmentMask 用 v4 Crystal4ContainmentMask，centerPoint = root.centerPoint
//     （组件中心），命中域为菱形（v3 原样，中心点随 x/y 同步自动更新）。
//   - hoverEnabled 默认 false：HoverHandler 只有消费方开启后才工作（v3 原样）。
// 与 v3 的刻意差异：无（仅 Style 对位 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import "NumTools.js" as Tools
import Qool.Color

/*!
    \qmltype ColorCursor
    \inqmlmodule Qool.Color
    \brief 滑块/表面控件取色光标（v3 逐字迁移）：菱形色块 + 悬停展开 + 刚移动高亮。

    用法二选一：绑定 \c x/y（滑块场景，配合 \c displayValue），或绑定
    \c centerx/centery（表面控件场景，HSVWheel/HSLBox 用 surface 坐标映射）。

    \section2 易误解点
    \list
    \li \c centerx/centery 是组件中心的坐标（x + width/2），不是左上角——滑块场景
        下 centerx/centery 只是同步副产品，滑块绑定的是 x/y；表面场景相反。
    \li 双向同步的写回不对称（onXChanged 有守卫、onCenterxChanged 无条件写）是
        v3 逐字行为，用来打破同步环；删掉无条件写会导致表面场景光标不跟随。
    \li \c hoveredSize 展开依赖三态之一（悬停/交互/刚移动），其中"刚移动"由
        movementTimer 在 x/y 变化后 1 秒内维持——这也是滑块拖停后光标短暂
        保持展开的原因（v3 交互反馈，勿当 bug 修）。
    \endlist
*/
Item {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property color currentColor: root.Style.highlight

    property real size: 20
    readonly property real hoveredSize: pControl.hoveredSize

    property bool userInteracting: false
    property bool hoverEnabled: false

    width: size
    height: size

    property real centerx
    property real centery
    readonly property point centerPoint: Qt.point(centerx, centery)

    Connections {
        target: root
        function onXChanged() {
            const v = x + width / 2
            if (root.centerx !== v)
                root.centerx = v
        }
        function onYChanged() {
            const v = y + height / 2
            if (root.centery !== v)
                root.centery = v
        }
        function onCenterxChanged() {
            const v = root.centerx - width / 2
            //            if (root.x - v == 0)
            root.x = v
        }
        function onCenteryChanged() {
            const v = centery - height / 2
            //            if (root.y - v == 0)
            root.y = v
        }
    }

    QtObject {
        id: pControl
        property bool initialized: false

        readonly property bool animationEnabled: initialized
                                                 && (!root.userInteracting)
                                                 && root.animationEnabled
        readonly property real hoveredSize: {
            let delta = root.size * 0.25
            delta = Tools.limitNumber(delta, 15, 45)
            return root.size + delta
        }
    }

    ColorCrystal {
        id: crystal
        size: root.size
        color: root.currentColor
        strokeColor: ThemeHQ.recommendForeground(root.currentColor)
        x: parent.width / 2
        y: parent.height / 2

        BasicNumberBehavior on size {
            enabled: pControl.animationEnabled
        }

        BasicColorBehavior on color {
            enabled: pControl.animationEnabled
        }

        BasicColorBehavior on strokeColor {
            enabled: pControl.animationEnabled
        }
    }

    HoverHandler {
        id: hoverer
        enabled: root.hoverEnabled
    }

    Timer {
        id: movementTimer

        property bool justMoved: false
        interval: 1000
        onTriggered: justMoved = false

        function when_moved() {
            justMoved = true
            restart()
        }
    }
    Connections {
        target: root
        function onXChanged() {
            movementTimer.when_moved()
        }
        function onYChanged() {
            movementTimer.when_moved()
        }
    }

    states: [
        State {
            when: hoverer.hovered || root.userInteracting
                  || movementTimer.justMoved
            PropertyChanges {
                crystal.size: pControl.hoveredSize
            }
        }
    ]

    Component.onCompleted: pControl.initialized = true

    containmentMask: Crystal4ContainmentMask {
        width: root.width
        height: root.height
        centerPoint: root.centerPoint
    }
}
