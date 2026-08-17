// NOTE(迁移) v3 Qool.Color/_private/ColorSlider.qml 逐字迁移（基类）。
// 依赖替换：TextLineEdit → NumInput（本模块拍平件，数值约定收拢到
// parseChannelValue）、NumberLimiter → 内联 QtObject（CutAtEdges [0,1]，
// 即 Math.max(0, Math.min(1, x))，v3 语义含 NaN 透传）、
// PixelFont.normalFont → PixelFont.normal（v4 单例）、
// Style.textColor → root.Style.text、Style.controlMovementDuration →
// root.Style.movementDuration；v3 的 `parent?.animationEnabled ?? Style.animationEnabled`
// 以 v4 惯例 root.Style.animationEnabled 替代（Style 附加属性沿对象树传播，
// 语义等价；消费方仍可直接覆写本属性）。
// 不再 import QtQuick.Controls / Qool.Controls / Qool.Color（本模块内部类型自可见）。
//
// 关键行为与易误解点（勿改）：
//   - 水平拖动映射：v = (mouseX - cursor.size / 2) / (slider.width - cursor.width)，
//     再 CutAtEdges [0,1]——分子是"光标中心相对轨道左端"的距离，分母是
//     "光标可滑动的行程"（轨道宽减光标宽），保证光标中心不越出轨道端部。
//   - 双击（onDoubleClicked）→ reset()：value 回到 defaultValue。
//   - value 与光标 displayValue 分离：拖动中（userInteracting）displayValue
//     不动画（Behavior 被门控关闭，光标跟手）；松手后 Behavior
//     （movementDuration）动画补位。
//   - 数值输入：编辑态用 NumInput.parseChannelValue（x > 1 → /1000，见 NumInput
//     头注释），再经 valueLimiter 限幅；非编辑态由 Binding 回写显示文本。
//   - 轨道高度跟随 cursor.hoveredSize（Layout.preferredHeight），悬停展开时
//     轨道同步变高，sliderBG 用 y 偏移保持轨道在展开区垂直居中（v3 原样）。
// 与 v3 的刻意差异：无（仅依赖替换 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "NumTools.js" as Tools
import Qool.Color

// 颜色通道水平滑块基类（v3 逐字迁移）：标题 + 数值输入一行，轨道 + 光标一行。
//
// 变体（ColorSlider_Hue/Value/Alpha）提供 `fillGradient` 与通道双向绑定；
// 本基类负责轨道外观（ColorSliderBackground）、光标（ColorCursor）、
// 拖动/双击/数值输入交互。
//
// 易误解点
// - 拖动映射的 `cursor.size/2` 偏移与 `cursor.width` 行程是刻意设计（见文件头
//   注释）——直接改成 `mouseX / width` 会改变光标行程与数值对应关系。
// - `displayValue` 与 `value` 是两回事：value 是数据面（输入输出），
//   displayValue 是光标动画面。拖动时门控动画，松手后平滑。
// - 双击重置为 `defaultValue`（各变体：Hue=0、Value=1、Alpha=1）。
// - 数值输入 x > 1 按 /1000 处理（允许键入 0..1000 表示 0..1 比例），
//   这是 v3 行为照迁，勿当 bug 修（详见 NumInput）。
Item {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property string title
    property real defaultValue: 0.5
    property real value: defaultValue

    property color displayColor
    property alias strokeWidth: sliderBG.strokeWidth
    property alias strokeColor: sliderBG.strokeColor
    property alias fillColor: sliderBG.fillColor
    property alias fillGradient: sliderBG.fillGradient
    property alias leftPoint: sliderBG.leftPoint
    property alias rightPoint: sliderBG.rightPoint

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    readonly property bool userInteracting: mouseArea.userInteracting

    QtObject {
        id: valueLimiter
        // v3 NumberLimiter(min:0, max:1, mode:CutAtEdges) 内联（NaN 透传，v3 一致）。
        function limit(x) {
            return Math.max(0, Math.min(1, x))
        }
    }

    GridLayout {
        id: mainLayout
        anchors.fill: parent
        Text {
            id: titleTest
            text: root.title
            font: PixelFont.normal
            color: root.Style.text
            Layout.column: 0
            Layout.row: 0
            Layout.leftMargin: 2
        }

        NumInput {
            id: valueText
            showUnderline: false
            text: Tools.simplifyChannelNumber(root.value)
            font: PixelFont.normal
            color: root.Style.text
            horizontalAlignment: Text.AlignRight
            Layout.column: 1
            Layout.row: 0
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
                    root.value = valueLimiter.limit(
                        valueText.parseChannelValue(valueText.text))
                }
            }
        }

        Item {
            id: slider
            Layout.row: 1
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.preferredHeight: cursor.hoveredSize

            ColorSliderBackground {
                id: sliderBG
                z: -1
                y: (cursor.hoveredSize - cursor.size) / 2
                width: slider.width
                height: cursor.size
                BasicColorBehavior on strokeColor {
                    enabled: root.animationEnabled
                }
            }

            InteractingArea {
                id: mouseArea
                function setValue() {
                    let v = (mouseX - cursor.size / 2) / (slider.width - cursor.width)
                    root.value = valueLimiter.limit(v)
                }

                onPressAndHold: setValue()

                onPositionChanged: {
                    if (mouseArea.userInteracting) {
                        setValue()
                    }
                }

                onDoubleClicked: root.reset()

                ColorCursor {
                    id: cursor
                    animationEnabled: root.animationEnabled
                    property real displayValue: root.value
                    BasicNumberBehavior on displayValue {
                        enabled: root.animationEnabled
                                 && (!root.userInteracting)
                        duration: root.Style.movementDuration
                    }

                    x: (slider.width - cursor.width) * displayValue
                    y: (parent.height - height) / 2
                    userInteracting: root.userInteracting
                    currentColor: root.displayColor
                }
            }
        }
    }

    function reset() {
        root.value = root.defaultValue
    }
}
