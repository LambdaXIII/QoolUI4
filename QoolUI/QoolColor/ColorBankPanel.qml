pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

/*!
    \qmltype ColorBankPanel
    \inqmlmodule Qool.Color
    \brief 色银行面板（v3 ColorBankPanel 迁移）：槽位网格 + L/S 存取交互。

    以 6 列网格展示 \l slots 个色槽（\l ColorBankSlotButton），
    槽位数据来自 \l colorBank（默认自有内存实例，可注入宿主实例）；
    当前色经 \l colorAssistant 提供，左右两半 L/S 区执行载入/存入。

    \section1 colorBank：默认自有实例，可注入（易误解，特别说明）

    \c colorBank 默认是\b 本面板自有的内存 \l ColorBank 实例
    （v3 的 \c useGlobalBank 持久化机制已随 v4 裁定移除，见
    color-migration-spec §2.5）——独立使用即成立，不需要外部准备。
    宿主可注入自己的实例（\c colorBank: myBank）共享数据：

    \list
    \li 注入\b 同一实例到多个面板 → 多面板数据互通（改一处处处可见）。
    \li 注入前宿主可先按需 \l {ColorBank::setColor}{setColor} 填充
        （持久化恢复），面板即显示已恢复数据。
    \endlist

    \section1 ColorBank 稀疏语义（易误解，特别说明）

    \l ColorBank 是无界\b 稀疏索引容器：只保留被显式写过的槽
    （存 slot_5 不创建 1..4）。\c slots 只是\b 显示范围——面板画
    0..slots-1 号格；\b 超出显示范围的槽照样可写入、可读取、不丢失
    （缩小 slots 再放大不会丢数据）。"显示 24 格"≠"最多存 24 个"。

    \section1 持久化刻意不做（宿主三接法）

    \l ColorBank 刻意不持久化（v3 QSettings 已移除），宿主自选接法：
    \list 1
    \li 注入前构造填充（恢复）：宿主构造自己的 \l ColorBank，
        按需 \l {ColorBank::setColor}{setColor()} 恢复旧数据再注入。
    \li 监听 \l {ColorBank::colorChanged}{colorChanged(n)} 纪录（保存）：
        每次变更写入宿主存储；配合 \l {ColorBank::filledIndexes}
        {filledIndexes()} 与 \l {ColorBank::color}{color()} 做启动
        批量恢复（读面）。
    \li 继承/仿写：子类化 \l ColorBank（protected 的 m_colors）或
        在宿主侧仿写相同接口，内嵌持久化逻辑。
    \endlist

    \section1 L/S 交互（v3 照迁）

    \list
    \li 槽格右半 \b S（存入）：\c colorBank.setColor(n, colorAssistant.color)
        ——当前色写入槽 n。
    \li 槽格左半 \b L（载入）：\c colorAssistant.color = slotColor
        ——槽色写回当前色。
    \li \c loadEnabled / \c saveEnabled：槽色与当前色\b 不同才可点
        （相同则无操作意义，v3 同构）。
    \li 槽号悬停淡出、L/S 淡入、按下前景高亮（\l ColorBankSlotButton
        内部行为）。
    \endlist

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Style.highlight }}——独立使用（不注入）
    即成立。

    \section1 属性

    \qmlproperty ColorBank ColorBankPanel::colorBank
    槽位存储后端（v3 同名 API 照迁）。默认自有内存实例；注入宿主
    实例即共享数据（见上"colorBank：默认自有实例，可注入"）。

    \qmlproperty ColorAssistant ColorBankPanel::colorAssistant
    当前色数据源（v3 同名 API 照迁）。L 区写回本属性、S 区读本属性
    存入。默认自带 \c Style.highlight 的实例。

    \qmlproperty int ColorBankPanel::slots
    显示槽位数，默认 24（6 列 × 4 行）。\b 只是显示范围，不是存储
    边界（见上"稀疏语义"）；改动即时改变网格格数。

    \qmlproperty bool ColorBankPanel::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}
    （v4 惯例）。传递给槽位按钮。
*/
GridLayout {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style），传给槽位按钮。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    // 显示范围（非存储边界）：只画 0..slots-1 号格。
    property int slots: 24

    // 默认自有内存实例；注入宿主实例即共享数据（见类文档三接法）。
    property ColorBank colorBank: ColorBank {}

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columns: 6
    columnSpacing: 4
    rowSpacing: 4

    Repeater {
        model: root.slots

        delegate: ColorBankSlotButton {
            required property int index
            animationEnabled: root.animationEnabled
            slotNumber: index
            slotColor: root.colorBank.color(index)

            onWannaSave: {
                slotColor = root.colorAssistant.color
                root.colorBank.setColor(index, slotColor)
            }

            onWannaLoad: root.colorAssistant.color = slotColor

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            loadEnabled: slotColor !== root.colorAssistant.color
            saveEnabled: slotColor !== root.colorAssistant.color
        } //slotButton
    } //Repeater
}
