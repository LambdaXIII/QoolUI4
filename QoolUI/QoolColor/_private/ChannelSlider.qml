// NOTE(迁移) v3 Qool.Color/_private/ChannelSlider.qml 逐字迁移（基类）。
// 依赖替换：TextLineEdit → NumInput、NumberLimiter → 内联 QtObject
// （CutAtEdges [0,1]）、PixelFont.normalFont → PixelFont.normal、
// Style.textColor → root.Style.text、Style.controlMovementDuration →
// root.Style.movementDuration、v3 的 parent 级 animationEnabled 回退 → v4 惯例
// root.Style.animationEnabled。
//
// **v3 bug 修复（刻意，勿回退）**：v3 数值输入 Connections 引用了未定义的
// `valueLimiter`（文件里只有 `limiter`）→ v3 中编辑数值会抛 ReferenceError
// 且通道值不更新；v4 修正为 `limiter.limit(...)`。若与 v3 源码逐字对照发现
// 此处不同，这是刻意修复（spec §5 修复项精神：迁移时一并修正 v3 缺陷）。
//
// 关键行为（勿改）：
//   - 竖直拖动映射：v = 1 - (mouseY / height)，CutAtEdges [0,1]——
//     向上拖数值增大；InteractingArea 锚定在 ChannelBar 上。
//   - 布局顺序（v3 原样）：轨道（fillHeight，preferredHeight 150）→
//     数值输入（72 宽，右对齐）→ 标题（fillWidth，居中，在底部）。
//   - ChannelBar.value 经 BasicNumberBehavior 门控动画（拖动中关闭，跟手；
//     非交互写入时平滑，duration = movementDuration）。
//   - 双击 → reset()：value 回 defaultValue（各变体默认 1）。
//   - 数值输入约定同 ColorSlider（NumInput.parseChannelValue，x>1 → /1000）。
// 与 v3 的刻意差异：仅 valueLimiter→limiter 修复；v3 数值输入上残留的
// Layout.column/row（ColumnLayout 中无效的属性）删除。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "NumTools.js" as Tools
import Qool.Color

// 通道竖直滑块基类（v3 逐字迁移）：ChannelBar 轨道 + 数值输入 + 底部标题。
//
// 变体（ChannelSlider_Red/Green/...）提供 `channelColor` 与通道双向绑定。
// `channelColor` 用于填充条与边框；`value` 由 `userInteracting` 门控的
// 两个互斥 Binding 与 colorAssistant 通道同步（见变体文件）。
//
// 易误解点
// - 竖直映射 v = 1 - mouseY/height（向上增大），与 ChannelBar 的
//   "从底部向上填充"配套——改任一侧都会错位。
// - 标题在底部（数值输入在轨道下方、标题在最下），v3 布局原样。
// - 数值编辑经 NumInput.parseChannelValue（x > 1 → /1000，v3 行为照迁）。
ColumnLayout {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property string title
    property color channelColor
    property real defaultValue: 1
    property real value: 1
    readonly property bool userInteracting: mouseArea.userInteracting

    ChannelBar {
        id: slider
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 150

        channelColor: root.channelColor
        value: root.value

        BasicNumberBehavior on value {
            enabled: root.animationEnabled && (!root.userInteracting)
            duration: root.Style.movementDuration
        }

        QtObject {
            id: limiter
            // v3 NumberLimiter(min:0, max:1, mode:CutAtEdges) 内联（NaN 透传，v3 一致）。
            function limit(x) {
                return Math.max(0, Math.min(1, x))
            }
        }

        InteractingArea {
            id: mouseArea
            function setValue() {
                let v = 1 - (mouseY / height)
                root.value = limiter.limit(v)
            }
            onPressAndHold: setValue()
            onPositionChanged: {
                if (mouseArea.userInteracting) {
                    setValue()
                }
            }
            onDoubleClicked: root.reset()
        }
    }

    NumInput {
        id: valueText
        showUnderline: false
        text: Tools.simplifyChannelNumber(root.value)
        font: PixelFont.normal
        color: root.Style.text
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 2
        Layout.preferredWidth: 72
        Binding {
            when: !valueText.editing
            valueText.text: Tools.simplifyChannelNumber(root.value)
            restoreMode: Binding.RestoreNone
        }
        Connections {
            enabled: valueText.editing
            target: valueText
            function onTextChanged() {
                root.value = limiter.limit(
                    valueText.parseChannelValue(valueText.text))
            }
        }
    }

    Text {
        id: titleTest
        text: root.title
        font: PixelFont.normal
        color: root.Style.text
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
    }

    function reset() {
        root.value = root.defaultValue
    }
}
