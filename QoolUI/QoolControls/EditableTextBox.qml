import QtQuick
import Qool.Controls.Components

// Qool.Controls.EditableTextBox：Qool 系列文本组件多行成品——BasicTextArea
// （Components 基底）+ 滚动（ScrollView 组合——官方成品 QC.ScrollView
// + 预设 Qool 主题滚动条）。
//
// 滚动：ScrollView（Qool.Controls——官方 QC.ScrollView
// 根，T.ScrollView 不转发 position/size 给附加滚动条、无样式让位，弃用）
// 对 TextArea 的集成（内容尺寸自动/背景不滚/clip 自动）；
// 滚动条 Qool 主题（垂直/水平均 ScrollBar——非 Qt 默认样式；水平
// AsNeeded，默认 Wrap 下不出现）。滚动条几何公式与内容让位内置在
// ScrollView（见其注释——ScrollView 附加机制只转发不设几何，公式须由
// 挂载处提供）。
//
// 文本 API 直通（property alias + 信号转发）：宿主只与本类型交互，内层文本
// 对象与编辑能力细节不暴露——无编辑会话（与 EditableText（单行编辑会话）
// 机制独立，仅命名同族）。BasicTextArea 预留的 textEdited/editingFinished
// 信号在本类型层消费转发（组件内连接——实例 handler 覆盖不适用）。
//
// 无背景（透明）：沿 BasicTextArea/EditableText 裸件约定——视觉背景由宿主
// 壳层提供。

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
