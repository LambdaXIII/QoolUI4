// NOTE(迁移) v3 Qool.Color/_private/InteractingArea.qml 逐字迁移。
// 契约（ColorSlider/ChannelSlider/HSVWheel/HSLBox/ColorQuickPicker 等消费方依赖）：
//   - userInteracting：按下置 true、释放置 false；消费方惯用法是在
//     onPositionChanged 中先检查 userInteracting 再更新值（v3 原样）。
//   - preventStealing + propagateComposedEvents：与父级/兄弟手势协调（v3 原样）。
//   - cursorShape 随 userInteracting 在 Blank/Cross 间切换。本件未开 hoverEnabled
//     （v3 即如此，cursorShape 的悬停生效依赖平台行为），勿添加 hoverEnabled。
//   - 本件是 MouseArea 子类：消费方可继续使用 MouseArea 的全部信号
//     （onPressed/onReleased/onPressAndHold/onPositionChanged/onDoubleClicked）
//     与属性（如 containmentMask，HSVWheel 以 surface 作掩码）。
// 与 v3 的刻意差异：无（本文件逐字，仅补注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

/*!
    \qmltype InteractingArea
    \inqmlmodule Qool.Color
    \brief 拖动交互区（v3 逐字迁移）：只负责按下/释放切换 \c userInteracting，拖动语义由消费方实现。

    本件刻意不做任何数值映射——各消费方的映射不同（水平滑块以鼠标 x 计算、
    竖直滑块以 y 计算、表面控件以二维坐标计算），统一在此处会引入两套行为，
    与 v3 滑块架构裁定（不合并基类）同理，映射留在消费方。

    \section2 易误解点
    \list
    \li \c userInteracting 只在按下/释放时切换；消费方必须在 \c onPositionChanged
        中自行检查它（v3 惯用法），本件不会"拦截"拖动事件做任何事。
    \li \c cursorShape 在按下期间为 \c Qt.BlankCursor（隐藏光标，拖动时不遮挡取色
        视觉），其余为 \c Qt.CrossCursor——这是 v3 的刻意交互反馈，勿删。
    \endlist
*/
MouseArea {
    id: root
    property bool userInteracting: false

    anchors.fill: parent

    cursorShape: userInteracting ? Qt.BlankCursor : Qt.CrossCursor

    preventStealing: true
    propagateComposedEvents: true

    onPressed: {
        userInteracting = true
    }

    onReleased: {
        userInteracting = false
    }
}
