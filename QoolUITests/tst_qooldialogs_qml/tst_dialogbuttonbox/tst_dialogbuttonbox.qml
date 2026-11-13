import QtQuick
import QtTest
import QtQuick.Templates as T
import Qool
import Qool.Dialogs

// DialogButtonBox 语义皮肤测试（Qool.Dialogs/DialogButtonBox.qml）
//
// 被测契约（本刀写的逻辑）：
// - `delegate: DialogButton {}` 接线：standardButtons 声明后，盒内按钮经
//   delegate 产出为 DialogButton，且按 attached role 呈现语义皮肤——
//   AcceptRole（Ok）→ positive、DestructiveRole（Discard）→ negative、
//   RejectRole（Cancel）→ 中性（button + controlBorderColor）
// - role→皮肤映射断言按 role 分类而非按下标——平台排序不进断言面
//
// 不设用例（Qt 既有机制，文档为准）：standardButtons 创建本身、
// attached 注入机制、role→信号分发、平台排序。
// padding/spacing/background（视觉协调字面量）不设用例——转 Example 冒烟
// 目检（实现期判据修正：字面量复读永不红）。
//
// 隔离策略：createTemporaryObject 独立实例；standardButtons 创建异步，
// tryCompare 轮询前置等待；颜色断言逐通道容差 0.02（QColor 量化误差，
// journal 有案）。

TestCase {
    id: root

    name: "DialogButtonBox"
    width: 400
    height: 300

    Component {
        id: boxComp
        DialogButtonBox {
            anchors.fill: parent
            standardButtons: T.DialogButtonBox.Ok | T.DialogButtonBox.Cancel
                             | T.DialogButtonBox.Discard
        }
    }

    Component {
        id: boxSizingComp
        DialogButtonBox {
            standardButtons: T.DialogButtonBox.Ok | T.DialogButtonBox.Cancel
        }
    }

    function colorClose(a, b) {
        return Math.abs(a.r - b.r) < 0.02
            && Math.abs(a.g - b.g) < 0.02
            && Math.abs(a.b - b.b) < 0.02
    }

    function test_standard_buttons_semantic_skin() {
        const box = createTemporaryObject(boxComp, root, {})
        tryCompare(box, "count", 3, 2000, "standard buttons created via delegate")

        for (let i = 0; i < box.count; ++i) {
            const btn = box.itemAt(i)
            verify(btn !== null, "itemAt(" + i + ") yields a button")
            const role = btn.T.DialogButtonBox.buttonRole
            if (role === T.DialogButtonBox.AcceptRole) {
                verify(colorClose(btn.backgroundSettings.fillColor, Style.positive),
                       "Ok/Accept fill is positive (index " + i + ")")
                verify(colorClose(btn.backgroundSettings.borderColor, Style.positive),
                       "Ok/Accept border is positive (index " + i + ")")
            } else if (role === T.DialogButtonBox.DestructiveRole) {
                verify(colorClose(btn.backgroundSettings.fillColor, Style.negative),
                       "Discard/Destructive fill is negative (index " + i + ")")
                verify(colorClose(btn.backgroundSettings.borderColor, Style.negative),
                       "Discard/Destructive border is negative (index " + i + ")")
            } else if (role === T.DialogButtonBox.RejectRole) {
                verify(colorClose(btn.backgroundSettings.fillColor, Style.button),
                       "Cancel/Reject fill is neutral (index " + i + ")")
                verify(colorClose(btn.backgroundSettings.borderColor, Style.controlBorderColor),
                       "Cancel/Reject border is neutral (index " + i + ")")
            } else {
                verify(false, "unexpected role " + role + " at index " + i)
            }
        }
    }

    // implicit 尺寸契约（回归守门）：Template 层 C++ contentItem 是裸 Item，
    // 控件自尺寸由样式层声明（Basic 手法）。声明缺失 → 盒 implicit 尺寸
    // 恒 0 → QoolDialog 内容反推尺寸不含按钮排 → footer 槽宽度为负、
    // 按钮宽度被均分成负值不可见 + 布局互喂 polish 循环（用户实报：
    // 无按钮 + 程序卡死）。删掉 DialogButtonBox.qml 的 implicit
    // 声明即可使本用例变红。
    function test_implicit_size_tracks_buttons() {
        const box = createTemporaryObject(boxSizingComp, root, {})
        tryCompare(box, "count", 2, 2000, "standard buttons created")
        tryVerify(function() { return box.implicitWidth > 0 }, 2000,
                  "box implicit width sums buttons (style-layer sizing)")
        tryVerify(function() { return box.implicitHeight > 0 }, 2000,
                  "box implicit height follows buttons")
        const minW = box.itemAt(0).implicitWidth + box.itemAt(1).implicitWidth
                     + box.spacing
        tryVerify(function() { return box.implicitWidth >= minW - 0.5 }, 2000,
                  "implicit width covers all buttons + spacing")
    }
}
