pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

ColumnLayout {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style），子件各自消费。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    // 默认状态自洽：默认实例自带默认色，独立使用即成立（v4 默认自洽原则）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    spacing: 4

    implicitHeight: 500
    implicitWidth: 200

    // 分类切换（v3 CycleChoiceButton 拍平为 CycleChoice）。
    // 分类数据来自 ColorNameHQ.categories()（插件声明分类的并集），
    // 本组件不内置分类数据。
    CycleChoice {
        id: profiler
        defaultIndex: 0
        // v3 同款：外部 font 赋值（PixelFont.normal，24px MozartNBP）
        // 覆盖 CycleChoice 内部 font.pixelSize 默认绑定（controlTextSize）
        // ——QML 组属性赋值会移除子属性绑定，v3 正是靠此把分类文字
        // 渲染为像素字体 24px（v3 用 PixelFont.normalFont，对位 PixelFont.normal）。
        font: PixelFont.normal
        texts: ColorNameHQ.categories()
        // cutSizes 便捷面删除迁移为四角显式：QoolColor 不在兼容范围
        //（04 票删除旧便捷面后本组件仍须可编译），四角值保持原统一值 2。
        backgroundSettings.cutSizeTL: 2
        backgroundSettings.cutSizeTR: 2
        backgroundSettings.cutSizeBL: 2
        backgroundSettings.cutSizeBR: 2
        Layout.fillWidth: true
    } //profiler

    // 色名列表（v3 ColorNameView 拍平，私有件）。
    ColorNameView {
        id: view
        clip: true
        category: profiler.displayText
        Layout.fillWidth: true
        Layout.fillHeight: true

        // 列表点选 → 写 colorAssistant.color（选择联动）。
        onCurrentColorChanged: {
            root.colorAssistant.color = currentColor
        }
    } //view

    // 外部同步：colorAssistant 被外部改色（且与新选中色不同）→ 取消选中。
    Connections {
        target: root.colorAssistant
        function onColorChanged() {
            if (root.colorAssistant.color != view.currentColor)
                view.deselect()
        }
    } //Connections
}
