// 竖直通道滑块轨道（填充条视觉件）：ColorChannelVerticalSlider 的
// background delegate 内容件——原 `_private/ChannelBar` 填充条视觉迁移
// （padding 4 / radius 5 / 填充值 0 端锚定生长 / 身份色渐变 / justMoved
// 高亮 / 无 hover / 无可见手柄），hue 通道为原理式彩虹背景 + 采样色填充。
//
// 本件为 Item（非 T.Control）——尺寸由模板自动布局，不需要 Control 的
// padding/contentItem/background 语义（padding 4 为手动内容内缩）。

import QtQuick
import Qool
import Qool.Color
import "ColorChannelVerticalColors.js" as Colors

Item {
    id: root
    objectName: "track"  // 测试定位（水平族 "track" 惯例）

    // —— 输入（ColorChannelVerticalSlider 注入——background delegate 内容
    // 契约）——
    property bool animationEnabled: false
    property int channel: 0
    property ColorAssistant colorAssistant: null
    property real value: 1
    property bool pressed: false
    // 播种完成标记（照搬水平族语义）：完成前平滑填充动画关闭——创建/
    // 播种期不动画（初始定位无动画惯例）
    property bool seedDone: false
    // 方向注入（background delegate 内容契约——水平族同款输入）：
    // horizontal/mirrored 由 ColorChannelVerticalSlider 透传模板派生值
    property bool horizontal: true
    property bool mirrored: false

    // —— 派生（readonly）——
    // Hue 通道（HSV/HSL 共用）→ 彩虹背景特化
    readonly property bool hueChannel: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
    // 彩虹升序：仅水平 LTR（值 0 在左）时 position 0 = hue 0；其余
    // （垂直 / 水平 RTL）position 0 = hue 1（反排）
    readonly property bool rainbowAscending: root.horizontal && !root.mirrored
    // value 的缓动层：填充色（fillColor）与填充尺寸同源缓动值——填充
    // 前沿随缓动值移动，与背景在 value 处位置对齐（spec「采样源 = 缓动
    // 中的填充位置」）。
    // 门控：seedDone（播种前不动画）&& animationEnabled && !pressed
    // （拖动跟手、非交互平滑）。
    property real smoothValue: root.value
    BasicNumberBehavior on smoothValue {
        enabled: root.seedDone && root.animationEnabled && !root.pressed
        duration: root.Style.movementDuration
    }
    // 填充/border 基色：hue 随 value 采样（原理式），非 hue 身份色恒等。
    // 供测试断言（readonly 属性暴露——非外观接口，高定内化不变）。
    readonly property color sampleColor: root.hueChannel ? Colors.sampleHueColor(root.channel, root.colorAssistant, root.smoothValue) : Colors.identityColor(root.channel, root.colorAssistant)
    // 填充基色：hue = 色相正常色（固定 sat/lightness 1——仅随 position
    // 变化色相，不受当前明暗影响，用户定案 2026-08-23）；非 hue = 身份色
    // 恒等（与 sampleColor 同值）。与 sampleColor（边框基色，hue 仍原理
    // 式）有意分叉：填充显示纯色相、明暗由背景彩虹承载。
    readonly property color fillColor: root.hueChannel ? Colors.hueNormalColor(root.channel, root.smoothValue) : root.sampleColor

    // —— 对象树（手动实现 ChannelBar 的 padding=4 / radius=5 布局）——
    // 内容区（padding 4 内缩）
    Item {
        anchors.fill: parent
        anchors.margins: 4

        // 背景：非 hue = 身份色 α0.1 淡染；hue = 彩虹渐变（11 档原理式，
        // 见下「彩虹方向」）
        Rectangle {
            id: bgRect
            objectName: "bgRect"
            anchors.fill: parent
            radius: 1  // = radius − padding = 5 − 4
            color: root.hueChannel ? "transparent" : Qt.alpha(root.sampleColor, 0.1)
            gradient: root.hueChannel ? rainbow : undefined
        }

        // 填充：锚定值 0 端、沿值增大方向生长（垂直自底向上 / 水平自值
        // 0 端、RTL 右锚），填充色 α0.9（前沿）→ α0.1（尾部）沿生长轴
        // 渐变——填充色在前沿（α0.9 那端），与平滑填充尺寸同源
        // （smoothValue），边界恒无缝
        Rectangle {
            id: fillRect
            objectName: "fillRect"
            radius: 1
            width: root.horizontal ? parent.width * root.smoothValue : parent.width
            height: root.horizontal ? parent.height : parent.height * root.smoothValue
            x: root.horizontal ? (root.mirrored ? parent.width - width : 0) : 0
            y: root.horizontal ? 0 : parent.height - height
            gradient: Gradient {
                id: fillGradient
                orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
                // 填充 α 渐变参数（调试——内聚在本 Gradient，不占 track 接口面）
                property real alphaLead: 0.9
                property real alphaTail: 0.1
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.fillColor, root.horizontal && !root.mirrored ? fillGradient.alphaTail : fillGradient.alphaLead)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.fillColor, root.horizontal && !root.mirrored ? fillGradient.alphaLead : fillGradient.alphaTail)
                }
            }
            // justMoved 由尺寸变化触发（垂直高变 / 水平宽变）：任何 value
            // 写入（含程序写入、动画中间值）都亮 1s——刻意行为（照搬 ChannelBar）
            onHeightChanged: movementTimer.when_moved()
            onWidthChanged: movementTimer.when_moved()
        }
    }

    // 边框：radius 4（= padding）、透明底、1px 描边——常态 = 采样色、
    // justMoved = lighter 1.4× 高亮（无 hover 态，照搬 ChannelBar）
    Rectangle {
        id: borderRect
        objectName: "borderRect"
        anchors.fill: parent
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: movementTimer.justMoved ? Qt.lighter(root.sampleColor, 1.4) : root.sampleColor
        BasicColorBehavior on border.color {
            enabled: root.animationEnabled
        }
    }

    // 刚移动高亮计时器（照搬 ChannelBar）：interval 1s、justMoved 电平
    Timer {
        id: movementTimer
        property bool justMoved: false
        interval: 1000
        onTriggered: justMoved = false
        function when_moved() {
            justMoved = true;
            restart();
        }
    }

    // 彩虹渐变（hue bg，11 档）：档色原理式跟随——HSVHue 档 p =
    // hsva(p, hsvSaturationF, hsvValueF, rainbow.alpha)、HSLHue 档 p =
    // hsla(p, hslSaturationF, hslLightnessF, rainbow.alpha)——随 assistant
    // 当前色动态变化（类似 HSVWheel/HSLBox 背景；与水平族 TrackHue 固定
    // hsva(p,1,1,1) 有意不同）。同源 ColorChannelSliderTrackHue——
    // Gradient 需 QML 对象声明，勿抽 JS；档色为动态绑定，非固定字面量。
    //
    // 方向（orientation 随形态切换：垂直 position 0 = 顶 / 水平 = 起点端）；
    // 彩虹沿值方向（hue 0 在值 0 端 → hue 1 在值 1 端）——垂直值 0 = 底，
    // 故 stops 反排（position 0 = hue 1，QML Gradient position 0 = 顶的
    // 陷阱）；水平 LTR 值 0 = 左，升序。统一公式：第 i 个 stop
    // （position = i/10）hue = rainbowAscending ? i/10 : (1 − i/10)。
    // alpha 统一为本 Gradient 的 alpha 属性（调试参数——改一处即变）。
    Gradient {
        id: rainbow
        orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
        property real alpha: 0.25
        GradientStop {
            position: 0
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0 : 1, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0 : 1, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.1
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.1 : 0.9, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.1 : 0.9, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.2
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.2 : 0.8, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.2 : 0.8, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.3
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.3 : 0.7, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.3 : 0.7, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.4
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.4 : 0.6, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.4 : 0.6, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.5
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.5 : 0.5, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.5 : 0.5, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.6
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.6 : 0.4, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.6 : 0.4, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.7
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.7 : 0.3, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.7 : 0.3, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.8
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.8 : 0.2, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.8 : 0.2, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 0.9
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 0.9 : 0.1, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 0.9 : 0.1, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
        GradientStop {
            position: 1
            color: root.channel === ColorNameHQ.HSVHue ? Qt.hsva(root.rainbowAscending ? 1 : 0, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, rainbow.alpha) : Qt.hsla(root.rainbowAscending ? 1 : 0, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, rainbow.alpha)
        }
    }
}
