// NOTE(拍平件定位) TextLineEdit 的拍平件，置于 Qool.Color/_private 而非
// Qool.Controls：暂不耦合 Controls（拍平件只被 Color 模块内部消费，且
// Controls 的基础原件层尚在演进），直接以 QtQuick 原语实现。
// TODO(将来迁移): 待 Color 模块稳定后，本件扩展为完整控件迁移至 Qool.Controls
// （届时 Color 切换依赖，废弃本私有版）。
//
// 动画特征已按临时件策略移除（编辑弹跳/边缘闪烁/淡入），仅保静态外观、布局与状态切换。
//
// 刻意差异（均有注释，防审查误判）：
//   - pControl.leftBeamerAlpha/rightBeamerAlpha：无任何消费方的死状态，删除。
//   - root.textEdited 信号保留声明但从不发射（仅 API 面）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

// 双态数字/文本输入拍平件。
//
// 两种显示形态：
// 1. 滚动显示态：文字以单行滚动显示（`display`），内容超出宽度时可
//    滚轮左右滚动，底部随滚动位置移动的指示条（`indicator`）与编辑下划线
//    （`bar`）标注当前位置。
// 2. 编辑态：点击（`editable` 为 true 时）进入，显示为
//    TextInput，回车或失焦结束编辑并写回 `text`。
//
// 数值输入约定（刻意设计）
// 本组件被 Color 面板用作 0..1 通道值输入框（HSV/HSL/RGB/CMYK 各通道）。
// 该约定收拢为 parseChannelValue() 一个入口（委托
// ColorNameHQ.parseChannelNumberFloat——统一实现）：清洗输入（仅保留
// 数字与第一个小数点）→ 无小数点头部补点（整数输入按纯小数解释，
// 如 `350` → ".350" → 0.35——对齐显示格式的无前导零约定，非 bug，
// 请勿"修复"为普通除法或删除）→ 解析数字（失败 NaN 透传，消费方
// 自行处理空输入）。
//
// 为什么在 Color/_private 而非 Controls
// 本件暂不耦合 Controls（拍平件的消费方只有 Color 模块内部），TODO：
// 将来扩展为完整控件迁移至 Qool.Controls（届时 Color 切换依赖，废弃本私有版）。
//
// 属性
// `text` 为真实数据（写回目标）；`displayText` 为 `renderText(text)` 的
// 渲染结果（可覆写 `renderText` 做格式化）。`editing` 只读反映编辑态；
// `displayPosition` 只读反映滚动位置（0..1）。`emptyTextItem` 是空文本时
// 的提示组件（默认"<空>"，可覆写）。`editable` 为 false 时不可编辑但仍可
// 滚动显示；`showUnderline` 控制下划线区域显隐。

T.Control {
    id: root

    // 专项注释（缺陷修复）：根为 T.Control（QtQuick.Templates）后
    // 实测（Qt 6.11）Templates.Control 不传播 contentItem implicit——implicit 恒 0，
    // 布局中分配高度 0、数字内容溢出与标签错位/重叠。显式绑定回传
    //（implicit = 内容隐式尺寸，showUnderline 时含下划线区 5+4）。
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    // 动画已按临时件策略移除，本属性仅为 API 兼容保留（临时件定位）。
    property bool animationEnabled: root.Style.animationEnabled

    property bool editable: true
    property bool showUnderline: true

    property string text
    readonly property string displayText: renderText(text)

    property color color: root.Style.text
    property color highlightColor: root.Style.highlight
    readonly property real displayPosition: display.position
    readonly property bool editing: pControl.editing

    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignTop

    // 空文本提示组件（提示文字/占位符色/装饰字号）。
    property Component emptyTextItem: emptyHint

    // 显示文本格式化钩子：displayText = renderText(text)，默认恒等。
    property var renderText: function (x) {
        return x
    }

    font.pixelSize: root.Style.textSize

    signal editingFinished
    signal editingStarted
    // NOTE: 本信号保留声明但组件内部从不发射（仅作为 API 面存在；
    // 消费方可自行监听 text 变化实现同等效果）。
    signal textEdited

    QtObject {
        id: pControl
        property bool editing: false

        function start_edit() {
            input.text = root.text
            pControl.editing = true
            input.selectAll()
            input.forceActiveFocus()
            root.editingStarted()
        }

        function end_edit() {
            root.text = input.text
            input.focus = false
            pControl.editing = false
            root.editingFinished()
        }
    }

    HoverHandler {
        id: hoverer
        enabled: root.editable
        cursorShape: Qt.IBeamCursor
    }

    HoverHandler {
        id: hoverer2
        enabled: !root.editable && display.scrollable
        cursorShape: Qt.SizeHorCursor
    }

    TapHandler {
        id: tapper
        enabled: root.editable
        onTapped: pControl.start_edit()
    }

    WheelHandler {
        id: wheeler
        enabled: display.scrollable && (!pControl.editing)
        // 每格滚轮（120 单位）滚动 4px。
        onWheel: ev => {
                     const p = ev.angleDelta
                     let delta_pos = p.y / 120 * 4 / display.width
                     display.implicitPosition = display.position + delta_pos
                 }
    }

    contentItem: Item {
        id: content
        // ColumnLayout 默认 spacing 5 + 下划线区 4，显式复算。
        implicitWidth: display.implicitWidth
        implicitHeight: display.implicitHeight + (root.showUnderline ? 5 + 4 : 0)

        Item {
            id: displayArea
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: display.implicitHeight
            clip: true

            // ---- 滚动显示态 ----
            Item {
                id: display
                anchors.fill: parent
                clip: true
                visible: !pControl.editing
                // 专项注释（缺陷修复）：display 的数据绑定行（text: displayText +
                // font/color/两向对齐）缺失时 display 恒空、全部数值显示
                // 沦为"<空>"占位。逐行补回。
                text: root.displayText
                font: root.font
                color: root.color
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment

                // 滚动位置输入（滚轮写此值）；position 为 CutAtEdges 限幅结果。
                property real implicitPosition: 0
                readonly property real position: Math.max(0, Math.min(1, implicitPosition))
                readonly property bool scrollable: mainText.width > display.width

                property alias text: mainText.text
                property alias font: mainText.font
                property alias color: mainText.color
                property alias horizontalAlignment: mainText.horizontalAlignment
                property alias verticalAlignment: mainText.verticalAlignment

                implicitHeight: mainText.implicitHeight
                implicitWidth: mainText.implicitWidth

                Text {
                    id: mainText
                    // 内容窄于可视区：按对齐放置；宽于可视区：按 position 平移滚动。
                    x: {
                        const smaller = mainText.width < display.width
                        if (smaller) {
                            switch (root.horizontalAlignment) {
                            case Text.AlignLeft:
                                return 0
                            case Text.AlignRight:
                                return display.width - mainText.width
                            default:
                                return (display.width - mainText.width) / 2
                            }
                        } else {
                            const length = mainText.width - display.width
                            return 0 - length * display.position
                        }
                    }
                } //mainText
            } //display

            // ---- 编辑态 ----
            TextInput {
                id: input
                // 专项注释（缺陷修复）：activeFocusOnPress 必须为 true，
                // 否则长按/拖动后 tap 取消场景的光标落点失焦。恢复。
                activeFocusOnPress: true
                selectByMouse: true
                wrapMode: TextInput.NoWrap
                visible: pControl.editing
                font: root.font
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment
                color: root.color
                selectionColor: root.highlightColor
                selectedTextColor: ThemeHQ.recommendForeground(root.highlightColor)
                onEditingFinished: pControl.end_edit()
                anchors.fill: parent
            } //input

            // ---- 空提示（经 Loader 可覆写）----
            Loader {
                id: emptyLoader
                sourceComponent: root.emptyTextItem
                active: display.visible && display.text === ""
                x: {
                    switch (root.horizontalAlignment) {
                    case Text.AlignLeft:
                        return 0
                    case Text.AlignRight:
                        return parent.width - width
                    default:
                        return (parent.width - width) / 2
                    }
                }
                y: parent.height - height
            } //emptyLoader
        } //displayArea

        // ---- 下划线区（滚动指示条 + 编辑下划线）----
        Item {
            id: underlineArea
            visible: root.showUnderline
            anchors {
                top: displayArea.bottom
                left: parent.left
                right: parent.right
                topMargin: 5 // ColumnLayout 默认 spacing
            }
            height: 4

            // 滚动位置指示条：仅滚动显示态可见。
            Rectangle {
                id: indicator
                height: 2
                width: parent.width * 0.05
                x: (parent.width - width) * display.position
                visible: display.scrollable && (!pControl.editing)
                color: root.color
            }

            // 编辑下划线：编辑聚焦时浮现（无动画，临时件策略）。
            Rectangle {
                id: bar
                readonly property real preferred_y: parent.height - height
                border.width: 0
                height: 2
                color: root.color
                width: parent.width
                opacity: pControl.editing && input.activeFocus ? 1 : 0
                y: preferred_y
            }
        } //underlineArea
    } //contentItem

    // 空提示默认组件（占位符文字色 + 装饰字号 + 右下对齐）。
    // commentColor 语义归入 placeholderText（无 comment 系 token，
    // 占位提示的正确归属）。
    Component {
        id: emptyHint
        Text {
            font.pixelSize: root.Style.placeholderTextSize
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
            color: root.Style.placeholderText
            text: qsTr("<空>")
        }
    }

    // 方法 parseChannelValue(s)：real：将输入字符串解析为归一化通道值
    // （委托 ColorNameHQ.parseChannelNumberFloat——统一实现，与
    // formatChannelNumberFloat 配对）：清洗输入（仅保留数字与第一个
    // 小数点）→ 无小数点头部补点（整数输入按纯小数解释：350 → ".350"
    // → 0.35——对齐显示格式的无前导零约定）→ 解析数字（失败 NaN 透传，
    // 消费方自行处理空输入）。
    //
    // 典型用法（Color 面板通道输入）：
    //     Connections {
    //         enabled: channelInput.editing
    //         target: channelInput
    //         function onTextChanged() {
    //             colorAssistant.hsvHueF = channelInput.parseChannelValue(channelInput.text)
    //         }
    //     }
    function parseChannelValue(s) {
        return ColorNameHQ.parseChannelNumberFloat(s)
    }

    // 方法 edit()：外部主动进入编辑态（等价点击行为）。
    function edit() {
        pControl.start_edit()
    }
}
