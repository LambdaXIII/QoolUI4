import QtQuick
import QtQuick.Templates as T

import Qool

// Qool.Controls.Components.BasicTextField：Qool 系列文本域单层基底——
// **主题化默认 TextField**（标准行为 + Qool 主题），不掺入行为决策。
// 系列可编辑控件（TextField 双层版的编辑层、ComboBox/SpinBox 的编辑域）
// 统一消费本类型作为编辑基底；亦可在宿主处作为普通文本域直接使用。
//
// 特化能力（相对 Qt 官方 TextField）：
// - rejected()：主动提交非法输入（Enter 且 validator 拒绝——判定见下）时
//   发出，编辑态保持（焦点仍在文本域）供用户修正；被动失焦不触发（焦点
//   已走，收尾交由上层控件）。
//   下沉理由（grilling 定案）：rejected 是**宣告型**能力——纯信号，不改变
//   标准行为，判定属纯文本域逻辑（无外层数值语义依赖）。放基底，双层版
//   TextField 编辑层一行转发即可，各消费方（ComboBox/SpinBox）零成本获得。
// - Esc 处理**不下沉**：本类型定位 = 主题化默认 TextField，不改变标准行为；
//   Esc 收尾是**行为型**（改变 Esc 键默认效果），属上层对"会话结束方式"
//   的控制——由使用方（如 TextField 双层版编辑层）自行处理。

T.TextField {
    id: root

    color: Style.text
    selectionColor: Style.highlight
    selectedTextColor: Style.highlightedText
    verticalAlignment: Text.AlignVCenter

    // background: Rectangle {
    //     border.width: 1
    //     border.color: root.Style.mid
    //     color: root.Style.base
    //     opacity: root.activeFocus ? 1 : 0
    // }

    /* Qool 扩展信号：主动提交非法输入（Enter 且 validator 拒绝）时发出——
       编辑态保持（焦点仍在文本域）供用户修正；被动失焦不触发（焦点已走，
       收尾由上层控件如 TextField/SpinBox 负责）。宿主可监听本信号提示
       输入无效。无 validator 时 acceptableInput 恒 true，本信号不发出。 */
    signal rejected()

    // 判定：editingFinished 由 Enter 或失焦触发；仅当焦点仍在（Enter 主动
    // 提交）且输入不被 validator 接受时发出 rejected——失焦时焦点已走
    // （activeFocus false），静默交给上层控件收尾。
    onEditingFinished: if (!root.acceptableInput && root.activeFocus)
                           root.rejected()
}
