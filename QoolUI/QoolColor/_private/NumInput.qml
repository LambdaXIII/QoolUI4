// NOTE(拍平件定位) v3 TextLineEdit 的拍平重写件，置于 Qool.Color/_private 而非
// v4 Qool.Controls：暂不耦合 v4 Controls（拍平件只被 Color 模块内部消费，且
// v4 Controls 的基础原件层尚在演进），直接以 QtQuick 原语实现。
// TODO(将来迁移): 待 Color 模块稳定后，本件扩展为完整控件迁移至 v4 Qool.Controls
// （届时 Color 切换依赖，废弃本私有版）——见 color-migration-spec §7-7。
//
// 拍平内容（v3 → 本文件内联）：
//   - TextLineEdit          （双态输入框架，本文件根）
//   - BasicScrollableText   （滚动显示：implicitPosition/position/scrollable 内联）
//   - BasicTextInput        （编辑输入：TextInput 内联）
//   - BasicText_Empty       （空提示：emptyTextItem 默认内联）
//   - NumberLimiter         （position 的 CutAtEdges 限幅，一行 Math 内联）
// 不再依赖：QtQuick.Controls / QtQuick.Layouts / Qool.Controls.Basic / numberhelper。
//
// 动画特征已按临时件策略移除（编辑弹跳/边缘闪烁/淡入），仅保静态外观、布局与状态切换。
//
// 与 v3 的刻意差异（均有注释，防审查误判）：
//   - pControl.leftBeamerAlpha/rightBeamerAlpha：v3 中无任何消费方的死状态，删除。
//   - root.textEdited 信号保留声明但 v3 亦从不发射（仅 API 面），行为照迁。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color

// 双态数字/文本输入拍平件（v3 `TextLineEdit` 全功能拍平）。
//
// 两种显示形态：
// 1. 滚动显示态：文字以单行滚动显示（`display`），内容超出宽度时可
//    滚轮左右滚动，底部随滚动位置移动的指示条（`indicator`）与编辑下划线
//    （`bar`）标注当前位置。
// 2. 编辑态：点击（`editable` 为 true 时）进入，显示为
//    TextInput，回车或失焦结束编辑并写回 `text`。
//
// 数值输入约定（刻意设计，v3 行为照迁）
// 本组件被 Color 面板用作 0..1 通道值输入框（HSV/HSL/RGB/CMYK 各通道）。
// v3 中该约定散落在各面板的 `Connections` 里，拍平件将其收拢为
// parseChannelValue() 一个入口，语义与 v3 逐字一致：
// - 输入 `x` > 1 时按 `x` / 1000 处理——允许用户直接键入 0..1000 的
//   整数来表示 0..1 的比例（如 `350` 表示 0.35），这是 v3 的面板行为，
//   不是 bug，请勿"修复"为普通除法或删除。
// - 结果限幅到 [0, 1]（与 v3 `Tools.limitNumber(x, 0, 1)` 等价；
//   NaN 透传，与 v3 一致，消费方自行处理空输入）。
//
// 为什么在 Color/_private 而非 Controls
// 本件暂不耦合 v4 Controls（拍平件的消费方只有 Color 模块内部），TODO：
// 将来扩展为完整控件迁移至 v4 Qool.Controls（届时 Color 切换依赖，废弃本私有版）。
//
// 属性
// `text` 为真实数据（写回目标）；`displayText` 为 `renderText(text)` 的
// 渲染结果（可覆写 `renderText` 做格式化）。`editing` 只读反映编辑态；
// `displayPosition` 只读反映滚动位置（0..1）。`emptyTextItem` 是空文本时
// 的提示组件（默认"<空>"，可覆写）。`editable` 为 false 时不可编辑但仍可
// 滚动显示；`showUnderline` 控制下划线区域显隐。

T.Control {
    id: root

    // 专项注释（缺陷修复）：v3 TextLineEdit 根为 QBasic.Control（QtQuick.Controls.Basic），
    // implicit 尺寸自动取自 contentItem；拍平件改根为 T.Control（QtQuick.Templates）后
    // 实测（Qt 6.11）Templates.Control 不传播 contentItem implicit——implicit 恒 0，
    // 布局中分配高度 0、数字内容溢出与标签错位/重叠。显式绑定回传（语义与 v3 一致：
    // implicit = 内容隐式尺寸，showUnderline 时含下划线区 5+4）。
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

    // 空文本提示组件；默认等价于 v3 BasicText_Empty（提示文字/占位符色/装饰字号）。
    property Component emptyTextItem: emptyHint

    // 显示文本格式化钩子：displayText = renderText(text)，默认恒等。
    property var renderText: function (x) {
        return x
    }

    font.pixelSize: root.Style.textSize

    signal editingFinished
    signal editingStarted
    // NOTE: 与 v3 一致，本信号保留声明但组件内部从不发射（v3 亦不发射，
    // 仅作为 API 面存在；消费方可自行监听 text 变化实现同等效果）。
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
        // v3 ColumnLayout 默认 spacing 5 + 下划线区 4，拍平后显式复算。
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

            // ---- 滚动显示态（v3 BasicScrollableText 内联）----
            Item {
                id: display
                anchors.fill: parent
                clip: true
                visible: !pControl.editing
                // 专项注释（缺陷修复）：拍平时丢失了 v3 BasicScrollableText 的
                // 数据绑定行（text: displayText + font/color/两向对齐，对照 v3
                // TextLineEdit.qml 的 BasicScrollableText 实例），display 恒空、
                // 全部数值显示沦为"<空>"占位。逐行补回。
                text: root.displayText
                font: root.font
                color: root.color
                horizontalAlignment: root.horizontalAlignment
                verticalAlignment: root.verticalAlignment

                // 滚动位置输入（滚轮写此值）；position 为 CutAtEdges 限幅结果
                //（v3 NumberLimiter 模式，等价 Math 内联）。
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

            // ---- 编辑态（v3 BasicTextInput 内联）----
            TextInput {
                id: input
                // 专项注释（缺陷修复）：v3 BasicTextInput 为 activeFocusOnPress: true，
                // 迁移静默翻转为 false（长按/拖动后 tap 取消场景的光标落点失焦）。恢复。
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

            // ---- 空提示（v3 BasicText_Empty 逻辑内联，经 Loader 可覆写）----
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

        // ---- 下划线区（v3 第二布局项：滚动指示条 + 编辑下划线）----
        Item {
            id: underlineArea
            visible: root.showUnderline
            anchors {
                top: displayArea.bottom
                left: parent.left
                right: parent.right
                topMargin: 5 // v3 ColumnLayout 默认 spacing
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

    // 空提示默认组件（等价 v3 BasicText_Empty：
    // 占位符文字色 + 装饰字号 + 右下对齐）。
    // v3 commentColor 语义在 v4 归入 placeholderText（v4 无 comment 系 token，
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

    // 方法 parseChannelValue(s)：real：将输入字符串解析为 0..1 归一化
    // 通道值（v3 面板行为收拢入口）。
    // - `parseFloat` 解析；
    // - 结果 `x` > 1 时按 `x` / 1000 处理（允许键入 0..1000 整数表示
    //   0..1 比例，v3 行为照迁——刻意设计，勿当 bug 修）；
    // - 限幅到 [0, 1]；NaN 透传（与 v3 `Tools.limitNumber` 一致，
    //   消费方自行处理空输入）。
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
        let x = parseFloat(s)
        if (x > 1)
            x = x / 1000
        if (x < 0)
            return 0
        if (x > 1)
            return 1
        return x
    }

    // 方法 edit()：外部主动进入编辑态（等价点击行为）。
    function edit() {
        pControl.start_edit()
    }
}
