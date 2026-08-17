// NOTE(迁移) v3 Qool.Color/_private/ColorBankSlotButton.qml 拍平重写。
// 拍平内容（v3 → 本文件内联）：
//   - QC.Control（QtQuick.Controls）→ T.Control（QtQuick.Templates）
//     ——v4 模块惯例，不再依赖 QtQuick.Controls。
//   - ColorPreviewer 背景 + L/S 双区交互照迁：左半 L（载入）、右半 S
//     （存入）；按下高亮（前景半透明覆盖）；悬停时中央槽号淡出、L/S
//     字母淡入（BasicNumberBehavior 门控）。
//   - ColorAssistant 上的 down 自定义属性（v3 写法）保留：按下态由
//     两个 MouseArea 的 containsPress 合成。
// Style 对位：PixelFont.normalFont→PixelFont.normal；
//   recommendedForegroundColor 用 ColorAssistant 派生属性（v3 同构，
//   委托 ThemeHQ.recommendForeground）。
// 与 v3 的刻意差异：无（行为逐字；Style/依赖对位见上）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

// 色银行槽位按钮（v3 ColorBankSlotButton 拍平）：色槽预览 + L/S 双区。
//
// 单个色银行槽位的交互格：背景为 ColorPreviewer（显示 `slotColor`，
// 含前景对比边框）；中央显示槽号，左右两半分别提供
// `L`（载入）/ `S`（存入）操作区。悬停时槽号淡出、L/S 字母淡入；
// 按下（L 或 S 区）时前景半透明高亮覆盖。
//
// L/S 交互（易误解，特别说明）
// - 左半 L（Load）：发出 wannaLoad——宿主把 `slotColor`
//   载入当前颜色（ColorBankPanel 中写 `colorAssistant.color`）。
//   仅在 `loadEnabled` 且 `slotColor` 有效（ColorAssistant
//   解析成功）时可点；禁用时光标为禁止符。
// - 右半 S（Save）：发出 wannaSave——宿主把当前颜色存入
//   本槽（ColorBankPanel 中写 `colorBank.setColor`）。
//   仅在 `saveEnabled` 时可点。
// - 本组件不自行读写 ColorBank——槽位数据与当前色通过
//   `slotColor` 属性双向由宿主接线（v3 同构）。
//
// 属性
// - 属性 `slotNumber`（int）：槽位编号，仅用于中央槽号显示（v3 同构）。
// - 属性 `slotColor`（color）：本槽颜色（数据面，宿主绑定
//   `colorBank.color(n)`）。注意：属性被宿主赋值后绑定断开（v3 同构），
//   由宿主负责写回 ColorBank.setColor。
// - 属性 `loadEnabled`（bool）：L 区可点开关，默认 true。
//   L 区额外要求 `slotColor` 有效。
// - 属性 `saveEnabled`（bool）：S 区可点开关，默认 true。
// - 属性 `animationEnabled`（bool）：动画总开关，默认继承父级或
//   Style.animationEnabled（v4 惯例）。
//
// 信号
// - 信号 wannaSave()：S 区被点击时发出（宿主负责存入 ColorBank）。
// - 信号 wannaLoad()：L 区被点击时发出（宿主负责载入当前色）。
T.Control {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    property int slotNumber
    property color slotColor

    property bool loadEnabled: true
    property bool saveEnabled: true

    signal wannaSave
    signal wannaLoad

    // 槽色数据源（v3 同构：down 按下态由两区 containsPress 合成）。
    ColorAssistant {
        id: assistant
        color: root.slotColor
        property bool down: load_ma.containsPress || save_ma.containsPress
    } //assistant

    background: ColorPreviewer {
        colorAssistant: assistant
        radius: 5
        implicitHeight: 30
        implicitWidth: 50

        // 按下高亮 + 前景对比边框（v3 同构）。
        Rectangle {
            anchors.fill: parent
            color: assistant.down ? Qt.alpha(assistant.recommendedForegroundColor, 0.5) : "transparent"
            border.width: 1
            border.color: assistant.recommendedForegroundColor
            radius: parent.radius
            BasicColorBehavior on border.color {}
        } //overlay
    } //background

    contentItem: Item {
        Text {
            font: PixelFont.normal
            text: root.slotNumber
            anchors.centerIn: parent
            color: assistant.recommendedForegroundColor
            opacity: (load_ma.containsMouse || save_ma.containsMouse) ? 0 : 1
            BasicNumberBehavior on opacity {
                enabled: root.Style.animationEnabled
            }
        } //slotNumberText

        // L 区：载入（左半）。
        MouseArea {
            id: load_ma
            width: parent.width / 2
            height: parent.height
            hoverEnabled: true
            cursorShape: enabled ? Qt.UpArrowCursor : Qt.ForbiddenCursor
            onClicked: root.wannaLoad()
            enabled: root.loadEnabled && assistant.isValid()
            propagateComposedEvents: true
            Text {
                font: PixelFont.normal
                text: "L"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                color: assistant.recommendedForegroundColor
                opacity: parent.containsMouse ? 1 : 0
                BasicNumberBehavior on opacity {
                    enabled: root.Style.animationEnabled
                }
            } //loadText
        } //load_ma

        // S 区：存入（右半）。
        MouseArea {
            id: save_ma
            x: parent.width / 2
            width: parent.width / 2
            height: parent.height
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            onClicked: root.wannaSave()
            enabled: root.saveEnabled
            propagateComposedEvents: true
            Text {
                font: PixelFont.normal
                text: "S"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                color: assistant.recommendedForegroundColor
                opacity: parent.containsMouse ? 1 : 0
                BasicNumberBehavior on opacity {
                    enabled: root.Style.animationEnabled
                }
            } //saveText
        } //save_ma
    } //contentItem
}
