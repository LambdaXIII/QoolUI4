pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

GridLayout {
    id: root

    // 动画总开关：父级属性 → Style 传播，传给槽位按钮。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 显示范围（非存储边界）：只画 0..slots-1 号格。
    property int slots: 24

    // 默认自有内存实例；注入宿主实例即共享数据（见类文档三接法）。
    property ColorBank colorBank: ColorBank {}

    // 默认状态自洽：默认实例自带默认色，独立使用即成立（v4 默认自洽原则）。
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
                // S（存入）：当前色写入槽 n。
                slotColor = root.colorAssistant.color;
                root.colorBank.setColor(index, slotColor);
            }

            // L（载入）：槽色写回当前色。
            onWannaLoad: root.colorAssistant.color = slotColor

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: implicitBackgroundHeight
            Layout.preferredWidth: implicitBackgroundWidth

            loadEnabled: slotColor !== root.colorAssistant.color
            saveEnabled: slotColor !== root.colorAssistant.color
        } //slotButton
    } //Repeater
}
