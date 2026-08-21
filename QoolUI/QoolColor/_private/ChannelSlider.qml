// 通道竖直滑块基类：ChannelBar 轨道 + 数值输入 + 底部标题（竖直拖动
// 映射 + userInteracting 门控的双向通道绑定）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "NumTools.js" as Tools
import Qool.Color

// 通道竖直滑块基类：ChannelBar 轨道 + 数值输入 + 底部标题。
//
// 变体（ChannelSlider_Red/Green/...）提供 `channelColor` 与通道双向绑定。
// `channelColor` 用于填充条与边框；`value` 由 `userInteracting` 门控的
// 两个互斥 Binding 与 colorAssistant 通道同步（见变体文件）。
//
// 易误解点
// - 竖直映射 v = 1 - mouseY/height（向上增大），与 ChannelBar 的
//   "从底部向上填充"配套——改任一侧都会错位。
// - 标题在底部（数值输入在轨道下方、标题在最下），布局原样。
// - 数值编辑经 NumInput.parseChannelValue（统一实现
//   ColorNameHQ.parseChannelNumberFloat——清洗+无点头部补点）。
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
            // NumberLimiter(min:0, max:1, mode:CutAtEdges) 语义内联（NaN 透传）。
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
