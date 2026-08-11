import QtQuick
import Qool.Controls.Components

// Qool.Controls.EditableTextBox：Qool 系列文本组件多行成品——BasicTextArea
// （Components 基底）+ 滚动（ScrollView 组合——官方成品 QC.ScrollView
// + 预设 Qool 主题滚动条）。
//
// 滚动：ScrollView（Qool.Controls——官方 QC.ScrollView
// 根，实测裁定 2026-08-11：T.ScrollView 不转发 position/size 给附加滚动条、
// 无样式让位，弃用）对 TextArea 的集成（内容尺寸自动/背景不滚/clip 自动）；
// 滚动条 Qool 主题（垂直/水平均 ScrollBar——非 Qt 默认样式；水平
// AsNeeded，默认 Wrap 下不出现）。滚动条几何公式与内容让位内置在
// ScrollView（见其注释——2026-08-11 实测：ScrollView 附加机制只转发
// 不设几何，公式须由挂载处提供）。
//
// 文本 API 直通（property alias + 信号转发）：宿主只与本类型交互，内层文本
// 对象与编辑能力细节不暴露——无编辑会话（与 EditableText（单行编辑会话）
// 机制独立，仅命名同族）。BasicTextArea 预留的 textEdited/editingFinished
// 信号在本类型层消费转发（组件内连接——实例 handler 覆盖不适用）。
//
// 无背景（透明）：沿 BasicTextArea/EditableText 裸件约定——视觉背景由宿主
// 壳层提供。

/*!
    \qmltype EditableTextBox
    \inqmlmodule Qool.Controls
    \inherits ScrollView

    \brief 多行文本输入框成品——BasicTextArea（Components 基底）+ 滚动
    （ScrollView 组合）。

    EditableTextBox 是 Qool 系列文本组件的多行成品：开箱即用的多行文本
    输入框。宿主给定尺寸（width/height 或 anchors.fill）即可输入，内容超出
    视口时垂直滚动。文本 API 经属性转发直通内层文本区（BasicTextArea——
    文本三色/字体/Wrap 折行/AlignTop 的 Qool 主题默认全保留）——宿主只与
    本类型交互，内层文本对象与编辑机制细节不暴露（无编辑会话——与
    \l EditableText（单行编辑会话）机制独立，仅命名同族）。

    \section1 接口兼容性

    继承 \l ScrollView（其继承 Qt Quick Controls 的 \l {QtQuick.Controls::ScrollView} /
    Pane）——官方 API 全部可用（contentData / effectiveScrollBarWidth /
    effectiveScrollBarHeight 等），宿主可参照官方文档。本类型不改变官方
    行为，仅预设 Qool 主题滚动条与文本 API 转发，以下仅文档化 Qool 设置
    与转发部分。

    \section1 文本 API（转发自内层文本区）

    下列属性/信号直通内层 BasicTextArea：

    \qmlproperty string text
    文本内容。

    \qmlproperty bool readOnly
    只读（官方语义）。

    \qmlproperty color color
    文本色——默认 Style.text。

    \qmlproperty color selectionColor
    选中背景色——默认 Style.highlight。

    \qmlproperty color selectedTextColor
    选中文本色——默认 Style.highlightedText。

    \qmlproperty int wrapMode
    换行模式——默认 TextEdit.Wrap（文本在视口宽度折行；改 NoWrap 可出现
    水平滚动）。

    \qmlproperty int textFormat
    文本格式——默认 PlainText。

    \qmlproperty bool selectByMouse
    鼠标选择——默认 true（官方默认）。

    \qmlsignal textEdited()
    文本被用户编辑时发出（转发自内层文本区；编辑后文本经 \l text 读取——
    与 \l EditableText 系列一致的无参语义）。

    \qmlsignal editingFinished()
    编辑结束（失焦）时发出（转发自内层文本区）。

    \section1 滚动

    滚动条由 ScrollView 预设（Qool 主题——垂直/水平均为 Qool
    ScrollBar；水平 AsNeeded——默认 Wrap 折行下不出现）。几何布局、内容
    让位、策略控制见 \l ScrollView。内容尺寸随文本自动增长、背景装饰
    不随内容滚动、自动裁剪——ScrollView 对 TextArea 的官方集成保证。

    \section1 行为与用法

    \list
    \li 宿主给定尺寸（width/height 或 anchors.fill）即可使用；默认隐式尺寸
        240×120（固定视口——不随文本增长）。
    \li Enter 换行、Tab 输入制表符、placeholderText 提示等行为与官方
        TextArea 一致（官方行为，本类型不改变）。
    \li 无背景（透明）：视觉背景由宿主壳层提供（BasicTextArea 裸件约定）。
    \li 字体：内层文本区默认 Style.controlTextSize 字号（Qool 主题）——本
        类型不转发 font（ScrollView 基座 Control.font 为 final 属性，QML
        无法重声明）。
    \li 文本内边距（padding）与滚动位置（contentY）不暴露——编辑能力细节
        不对外；宿主需要时自行用 ScrollView/TextArea 组合。
    \endlist
*/

ScrollView {
    id: root

    // 文本 API 直通（property alias——独立传递，内层对象不暴露）
    property alias text: textArea.text
    property alias readOnly: textArea.readOnly
    property alias color: textArea.color
    property alias selectionColor: textArea.selectionColor
    property alias selectedTextColor: textArea.selectedTextColor
    property alias wrapMode: textArea.wrapMode
    property alias textFormat: textArea.textFormat
    property alias selectByMouse: textArea.selectByMouse

    // 信号转发（BasicTextArea 预留信号的首个消费方——组件内连接，宿主连 root）
    signal textEdited
    signal editingFinished

    BasicTextArea {
        id: textArea
        // 视口宽度折行（垂直滚动语义——内容高度随文本增长，水平不滚动）

        selectByMouse: !readOnly

        onTextEdited: root.textEdited()
        onEditingFinished: root.editingFinished()

        Keys.onEscapePressed: focus = false
    }

    // 默认尺寸 240×120（固定视口——不随文本增长）
    implicitWidth: 240
    implicitHeight: 120
}
