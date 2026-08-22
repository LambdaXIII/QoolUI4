// 竖直通道滑块轨道（填充条视觉件）：ColorChannelVerticalSlider 的
// background delegate 内容件——原 `_private/ChannelBar` 填充条视觉迁移
// （padding 4 / radius 5 / 从底部填充 / 身份色渐变 / justMoved 高亮 /
// 无 hover / 无可见手柄），hue 通道为原理式彩虹背景 + 采样色填充。
//
// 本件为 Item（非 T.Control）——尺寸由模板自动布局，不需要 Control 的
// padding/contentItem/background 语义（padding 4 为手动内容内缩）。

pragma ComponentBehavior: Bound

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

    // —— 派生（readonly）——
    // Hue 通道（HSV/HSL 共用）→ 彩虹背景特化
    readonly property bool hueChannel: root.channel === ColorNameHQ.HSVHue
                                       || root.channel === ColorNameHQ.HSLHue
    // value 的缓动层：采样色与填充高度同源缓动值——保证「填充顶边色 =
    // 采样色在顶边位置」无缝（spec「采样源 = 缓动中的填充高度」）。
    // 门控：seedDone（播种前不动画）&& animationEnabled && !pressed
    // （拖动跟手、非交互平滑）。
    property real smoothValue: root.value
    BasicNumberBehavior on smoothValue {
        enabled: root.seedDone && root.animationEnabled && !root.pressed
        duration: root.Style.movementDuration
    }
    // 填充/border 基色：hue 随 value 采样（原理式），非 hue 身份色恒等。
    // 供测试断言（readonly 属性暴露——非外观接口，高定内化不变）。
    readonly property color sampleColor: root.hueChannel
                                         ? Colors.sampleHueColor(root.channel, root.colorAssistant, root.smoothValue)
                                         : Colors.identityColor(root.channel, root.colorAssistant)

    // —— 对象树（手动实现 ChannelBar 的 padding=4 / radius=5 布局）——
    // 内容区（padding 4 内缩）
    Item {
        anchors.fill: parent
        anchors.margins: 4

        // 背景：非 hue = 身份色 α0.1 淡染；hue = 彩虹渐变（11 档原理式，
        // 见下「彩虹反排」）
        Rectangle {
            id: bgRect
            objectName: "bgRect"
            anchors.fill: parent
            radius: 1  // = radius − padding = 5 − 4
            color: root.hueChannel ? "transparent" : Qt.alpha(root.sampleColor, 0.1)
            gradient: root.hueChannel ? rainbow : undefined
        }

        // 填充：从底部向上（高度 = value × 高），采样色 α0.9（顶）→
        // α0.1（底）纵向渐变——采样色在顶边（α0.9 那端），与平滑填充
        // 高度同源（smoothValue），边界恒无缝
        Rectangle {
            id: fillRect
            objectName: "fillRect"
            width: parent.width
            radius: 1
            height: parent.height * root.smoothValue
            y: parent.height - height
            gradient: Gradient {
                GradientStop {
                    position: 0  // 顶
                    color: Qt.alpha(root.sampleColor, 0.9)
                }
                GradientStop {
                    position: 1  // 底
                    color: Qt.alpha(root.sampleColor, 0.1)
                }
            }
            // justMoved 由高度变化触发：任何 value 写入（含程序写入、动画
            // 中间值）都亮 1s——刻意行为（照搬 ChannelBar）
            onHeightChanged: movementTimer.when_moved()
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
        border.color: movementTimer.justMoved ? Qt.lighter(root.sampleColor, 1.4)
                                              : root.sampleColor
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
            justMoved = true
            restart()
        }
    }

    // 彩虹渐变（hue bg，11 档）：档色原理式跟随——HSVHue 档 p =
    // hsva(p, hsvSaturationF, hsvValueF, 0.2)、HSLHue 档 p =
    // hsla(p, hslSaturationF, hslLightnessF, 0.2)——随 assistant 当前色
    // 动态变化（类似 HSVWheel/HSLBox 背景；与水平族 TrackHue 固定
    // hsva(p,1,1,1) 有意不同）。同源 ColorChannelSliderTrackHue——
    // Gradient 需 QML 对象声明，勿抽 JS；档色为动态绑定，非固定字面量。
    //
    // 实现陷阱（勿"修正"）：QML Gradient position 0 = 顶部，而 spec 要求
    // 「hue 0 底部 → hue 1 顶部」——stops 必须反排：position 0（顶）=
    // hue 1、position 1（底）= hue 0。第 i 个 stop（position = i/10）的
    // color = hsva(1 − i/10, …)（或 hsla）。
    Gradient {
        id: rainbow
        GradientStop {
            position: 0
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(1, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(1, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.1
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.9, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.9, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.2
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.8, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.8, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.3
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.7, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.7, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.4
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.6, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.6, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.5
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.5, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.5, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.6
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.4, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.4, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.7
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.3, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.3, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.8
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.2, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.2, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 0.9
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0.1, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0.1, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
        GradientStop {
            position: 1
            color: root.channel === ColorNameHQ.HSVHue
                   ? Qt.hsva(0, root.colorAssistant.hsvSaturationF, root.colorAssistant.hsvValueF, 0.2)
                   : Qt.hsla(0, root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF, 0.2)
        }
    }
}
