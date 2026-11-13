import QtQuick
import QtTest
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components
import Qool.Dialogs

// DialogButton 语义皮肤测试（Qool.Dialogs/DialogButton.qml）
//
// 被测契约（本刀写的逻辑）：
// - role→语义色映射：无 role → 中性（button + controlBorderColor +
//   buttonText）；AcceptRole/YesRole → positive（锁定两 role 同映射）；
//   DestructiveRole → negative；InvalidRole 回设恢复中性（分支覆盖）
// - 对比度契约：语义填充时前景文字 = ThemeHQ.recommendForeground(fillColor)
// - 主题跟随：语义填充来自 Style.positive 绑定——节点级 Style 覆盖后
//   填充跟随（抓快照式硬编码实现；覆盖是节点级、不向子孙传播，
//   先例 tst_qool_qml/tst_style/tst_style.qml C5，故覆盖必须落按钮
//   实例节点）
// - 强调通道：highlighted → highlightCover opacity 1（聚合表达式
//   `highlighted || hovered` 是本刀写的绑定；hover 为 Qt 侧源，不单独设用例）
//
// 不设用例（Qt 既有机制）：attached 注入本身、hover 行为。
//
// 隔离策略：每函数 createTemporaryObject 独立实例（role 赋值不跨用例
// 泄漏，无需还原覆盖）；颜色断言逐通道容差 0.02（QColor 通道量化误差，
// journal 有案——0.001 容差必失败）。

TestCase {
    id: root

    name: "DialogButton"
    width: 200
    height: 100

    Component {
        id: btnComp
        DialogButton {
            anchors.centerIn: parent
            text: "Btn"
        }
    }

    function colorClose(a, b) {
        return Math.abs(a.r - b.r) < 0.02
            && Math.abs(a.g - b.g) < 0.02
            && Math.abs(a.b - b.b) < 0.02
    }

    function test_default_neutral_skin() {
        const btn = createTemporaryObject(btnComp, root, {})
        verify(colorClose(btn.backgroundSettings.fillColor, Style.button),
               "no role fill is neutral button")
        verify(colorClose(btn.backgroundSettings.borderColor, Style.controlBorderColor),
               "no role border is neutral controlBorderColor")
        verify(colorClose(btn.contentItem.color, Style.buttonText),
               "no role text is neutral buttonText")
    }

    function test_role_accept_semantic() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.AcceptRole
        verify(colorClose(btn.backgroundSettings.fillColor, Style.positive),
               "Accept fill is positive")
        verify(colorClose(btn.backgroundSettings.borderColor, Style.positive),
               "Accept border is positive")
        verify(colorClose(btn.contentItem.color,
                          ThemeHQ.recommendForeground(Style.positive)),
               "Accept text keeps contrast on semantic fill")
    }

    function test_role_yes_semantic() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.YesRole
        verify(colorClose(btn.backgroundSettings.fillColor, Style.positive),
               "YesRole maps to positive like AcceptRole")
        verify(colorClose(btn.backgroundSettings.borderColor, Style.positive),
               "YesRole border is positive")
    }

    function test_role_destructive_semantic() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.DestructiveRole
        verify(colorClose(btn.backgroundSettings.fillColor, Style.negative),
               "Destructive fill is negative")
        verify(colorClose(btn.backgroundSettings.borderColor, Style.negative),
               "Destructive border is negative")
        verify(colorClose(btn.contentItem.color,
                          ThemeHQ.recommendForeground(Style.negative)),
               "Destructive text keeps contrast on semantic fill")
    }

    // 裁剪项锁定（AGENTS.md「覆盖完整度」）：checked 无专属视觉——回填
    // ToolButton 式 checked Binding 块会使本用例变红。
    function test_checked_visual_trimmed() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.checked = true
        verify(colorClose(btn.backgroundSettings.fillColor, Style.button),
               "checked does not restyle fill (trimmed contract)")
        verify(colorClose(btn.backgroundSettings.borderColor, Style.controlBorderColor),
               "checked does not restyle border (trimmed contract)")
        verify(colorClose(btn.contentItem.color, Style.buttonText),
               "checked does not restyle text (trimmed contract)")
    }

    function test_role_revert_to_neutral() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.AcceptRole
        verify(colorClose(btn.backgroundSettings.fillColor, Style.positive),
               "precondition: semantic fill active")
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.InvalidRole
        verify(colorClose(btn.backgroundSettings.borderColor, Style.controlBorderColor),
               "InvalidRole reverts border to neutral")
        verify(colorClose(btn.contentItem.color, Style.buttonText),
               "InvalidRole reverts text to neutral")
    }

    // 主题跟随：语义填充必须来自 Style.positive 绑定而非快照。
    // 覆盖落在被测按钮实例自身节点（Style attached 覆盖节点级、不向子孙
    // 传播——落 TestCase 根不可达按钮，断言永不红）。
    function test_semantic_fill_follows_theme_token() {
        const btn = createTemporaryObject(btnComp, root, {})
        btn.T.DialogButtonBox.buttonRole = T.DialogButtonBox.AcceptRole
        verify(colorClose(btn.backgroundSettings.fillColor, Style.positive),
               "precondition: semantic fill active")
        const alien = Qt.color("#800080")
        btn.Style.positive = alien
        tryCompare(btn.backgroundSettings, "fillColor", alien, 1000,
                   "fill follows node-level Style.positive override")
    }

    function test_highlighted_emphasis_cover() {
        const btn = createTemporaryObject(btnComp, root, {})
        const cover = btn.children.find(c => c instanceof ControlHighlightCover)
        verify(cover !== undefined, "highlight cover present")
        tryCompare(cover, "opacity", 0, 1000)
        btn.highlighted = true
        tryCompare(cover, "opacity", 1, 1000, "highlighted raises cover")
        btn.highlighted = false
        tryCompare(cover, "opacity", 0, 1000, "unhighlight lowers cover")
    }
}
