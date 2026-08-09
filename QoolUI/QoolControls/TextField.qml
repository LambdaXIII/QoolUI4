import QtQuick
import Qool.Controls.Components
import Qool

// Qool.Controls.TextField：Qool 系列文本域的强化版本（继承 BasicTextField——
// Components 层的 Qool 样式文本域）。系列控件（ComboBox/SpinBox/...）统一
// 使用本类型作为编辑域：Qool 特有文本域能力收束于此，后续调整一处生效、
// 效果统一（单一事实源）。
//
// 特化能力（相对 BasicTextField）：
// - rejected()：主动提交非法输入（Enter 且 validator 拒绝，acceptableInput
//   false）时发出，编辑态保持（焦点留在文本域）供修正；被动失焦不触发
//   （收尾交由外层控件）。宿主可监听以提示用户。
//   判定：editingFinished 在 Enter/失焦都会发出，仅当焦点仍在（主动提交）
//   且 validator 拒绝时发出 rejected；无 validator 时 acceptableInput 恒
//   true，永不拒绝。
// - Esc 结束编辑：按 Esc 释放焦点，与失焦同路径（editingFinished 照常发出，
//   收尾语义由外层控件/宿主决定——文本域层不区分"取消/提交"）。

BasicTextField {
    id: root

    /* Qool 扩展信号：主动提交非法输入（Enter 且 validator 拒绝）时发出——
       编辑态保持（焦点仍在文本域）供用户修正；被动失焦不触发（焦点已走，
       收尾由外层控件如 SpinBox 负责）。宿主可监听本信号提示用户输入无效。
       无 validator 时无拒绝，本信号不发出。 */
    signal rejected()

    // 判定：editingFinished 由 Enter 或失焦触发；仅当焦点仍在（Enter 主动
    // 提交）且输入不被 validator 接受时发出 rejected——失焦时焦点已走
    // （activeFocus false），静默交给外层控件收尾。
    onEditingFinished: if (!root.acceptableInput && root.activeFocus)
                           root.rejected()

    // Esc 结束编辑：释放焦点（= 失焦路径，editingFinished 照常触发），
    // 不做文本恢复——"取消到哪"是外层控件的收尾语义，文本域只宣告结束。
    Keys.onEscapePressed: root.focus = false
}
