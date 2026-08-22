// 竖直通道滑块轨道（填充条视觉件）：ColorChannelVerticalSlider 的
// background delegate 内容件。Item 非 T.Control——尺寸由模板自动布局。

import QtQuick
import Qool
import Qool.Color
import "ColorChannelVerticalColors.js" as Colors

Item {
    id: root
    objectName: "track"  // 测试定位

    // —— 输入（ColorChannelVerticalSlider 注入）——
    property bool animationEnabled: false
    property int channel: 0
    property ColorAssistant colorAssistant: null
    property real value: 1
    property bool pressed: false
    // 播种完成前填充动画关闭（初始定位无动画）
    property bool seedDone: false
    property bool horizontal: true
    property bool mirrored: false

    // —— 派生 ——
    // Hue 通道（HSV/HSL 共用）→ 彩虹背景特化
    readonly property bool hueChannel: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
    // 彩虹升序：仅水平 LTR（值 0 在左）position 0 = hue 0；其余反排
    readonly property bool rainbowAscending: root.horizontal && !root.mirrored
    // 缓动层：填充色与填充尺寸同源（采样源 = 缓动中的填充位置）
    property real smoothValue: root.value
    BasicNumberBehavior on smoothValue {
        enabled: root.seedDone && root.animationEnabled && !root.pressed
        duration: root.Style.movementDuration
    }
    // 边框基色：hue 随 value 原理式采样，非 hue 身份色恒等
    readonly property color sampleColor: root.hueChannel ? Colors.sampleHueColor(root.channel, root.colorAssistant, root.smoothValue) : Colors.identityColor(root.channel, root.colorAssistant)
    // 填充基色：hue = 色相正常色（固定 sat/lightness 1，不受当前明暗——
    // 明暗由背景彩虹承载，用户定案）；非 hue = 身份色。与 sampleColor
    // 有意分叉（填充纯色相 vs 边框原理式）。
    readonly property color fillColor: root.hueChannel ? Colors.hueNormalColor(root.channel, root.smoothValue) : root.sampleColor

    // —— 对象树（padding=4 手动内缩）——
    Item {
        anchors.fill: parent
        anchors.margins: 4

        // 背景：非 hue = 身份色 α0.1 淡染；hue = 彩虹渐变
        Rectangle {
            id: bgRect
            objectName: "bgRect"
            anchors.fill: parent
            radius: 1  // = radius − padding = 5 − 4
            color: root.hueChannel ? "transparent" : Qt.alpha(root.sampleColor, 0.1)
            gradient: root.hueChannel ? rainbow : undefined
        }

        // 填充：锚定值 0 端、沿值增大方向生长（垂直自底向上 / 水平自值
        // 0 端、RTL 右锚）；α 渐变（前沿 0.9 → 尾部 0.1）沿生长轴
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
            // justMoved 由尺寸变化触发：任何 value 写入（含程序写入、动画
            // 中间值）都亮 1s——刻意行为
            onHeightChanged: movementTimer.when_moved()
            onWidthChanged: movementTimer.when_moved()
        }
    }

    // 边框：radius 4（= padding）、1px 描边——常态采样色、justMoved
    // lighter 1.4× 高亮（无 hover 态）
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

    // 刚移动高亮（interval 1s）
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
    // hsva(p, hsvSaturationF, hsvValueF)、HSLHue 档 p =
    // hsla(p, hslSaturationF, hslLightnessF)——随 assistant 当前色动态
    // 变化（与水平族 TrackHue 固定 hsva(p,1,1,1) 有意不同）。
    //
    // 方向陷阱：QML Gradient position 0 = 起点端——垂直 position 0 = 顶，
    // 而值 0 端在底（填充自底向上），故 stops 反排（position 0 = hue 1）；
    // 水平 LTR 值 0 = 左，升序。统一公式：第 i 个 stop hue =
    // rainbowAscending ? i/10 : (1 − i/10)。
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
