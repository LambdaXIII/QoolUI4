pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

/*!
    \qmltype ColorNameList
    \inqmlmodule Qool.Color
    \brief 色名列表（v3 ColorNameList 迁移）：分类切换 + 色名点选联动。

    自顶向下组合：
    \list 1
    \li \l CycleChoice 分类切换器：选项为 \l {ColorNameHQ}{ColorNameHQ.categories()}
        返回的插件分类（如默认插件的 "DEFAULT"）。
    \li \l ColorNameView 色名列表：显示当前分类下全部色名，点选联动
        \l colorAssistant。
    \endlist

    \section1 选择联动（v3 照迁）

    \list
    \li 列表点选色名 → \c currentColor 变化 → 写 \c colorAssistant.color。
    \li \c colorAssistant.color 被外部改变（且与新选中色不同）→ 取消
        列表当前选中（\c deselect）——外部同步与列表选择互斥，避免
        列表选中态与外部颜色不一致。
    \endlist

    \section1 分类切换（易误解，特别说明）

    分类数据来自 \l {ColorNameHQ}{ColorNameHQ.categories()}（插件声明分类的
    并集，v3 同 API）；切换走 \l CycleChoice（v4 拍平件），每次点击
    循环到下一分类，\c displayText 即当前分类名。\b 本组件不内置
    分类数据——分类全集由已安装插件决定（v3 行为照迁）。

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Style.highlight }}——独立使用（不注入）
    即成立。

    \section1 尺寸

    默认 \c implicitHeight: 500 / \c implicitWidth: 200（v3 同）；
    宿主可覆写，或放入布局由 \c Layout.fill* 控制。

    \section1 属性

    \qmlproperty ColorAssistant ColorNameList::colorAssistant
    颜色数据源（v3 同名 API 照迁）。列表点选写本属性；
    外部写本属性会触发列表取消选中（见上"选择联动"）。
    默认自带 \c Style.highlight 的实例。

    \qmlproperty bool ColorNameList::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}
    （v4 惯例）。传递给内部 \l CycleChoice 与 \l ColorNameView
    （v3 同款传播）。
*/
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
