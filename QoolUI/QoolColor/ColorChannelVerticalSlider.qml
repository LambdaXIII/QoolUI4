import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color
import Qool.Controls.Components
import "_private"

T.Slider {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorNameHQ.HSLHue
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    orientation: Qt.Vertical  // 默认竖直（T.Slider 默认 horizontal，须显式）

    // 默认 1 = hue 1≡0 循环等价；实际值由 onCompleted 播种
    value: 1

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    background: Item {
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150
        RectShape {
            anchors.fill: parent
            radius: 4
            borderWidth: 1
            color: Qt.alpha(pCtrl.channelColor, 0.1)
            borderColor: pCtrl.channelColor
            BasicColorBehavior on borderColor {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicColorBehavior on color {
                enabled: pCtrl.animationReallyEnabled
            }

            fillGradient: {
                if (pCtrl.isHue)
                    return rainbow.createObject();
                return null;
            }
            Component {
                id: rainbow
                RainbowGradient {
                    width: root.availableWidth
                    height: root.availableHeight
                    horizontal: root.horizontal
                    mirrored: root.mirrored
                }
            }//rainbow
        }//rectShape
    }//background

    // 透明手柄（side×side）：无可见视觉、无 hover 反馈——交互全由模板
    // 控制层承担，栏上其余位置点击跳转。定位走 visualPosition。
    handle: Item {
        width: pCtrl.side
        height: pCtrl.side
        x: {
            if (root.horizontal)
                return root.leftPadding + root.visualPosition * (root.availableWidth - width);
            else
                return root.leftPadding + (root.availableWidth - width) / 2;
        }
        y: {
            if (root.horizontal)
                return root.topPadding + (root.availableHeight - height) / 2;
            else
                return root.topPadding + root.visualPosition * (root.availableHeight - height);
        }
        MouseArea {
            objectName: "handleCursorArea"  // 测试定位
            enabled: root.enabled
            anchors.fill: parent
            acceptedButtons: Qt.NoButton //仅处理鼠标变形
            cursorShape: root.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }
    }

    contentItem: Item {
        id: fillBox
        readonly property real innerPadding: 4
        Rectangle {
            id: filler
            radius: 2
            x: root.horizontal && root.mirrored ? fillBox.width - fillBox.innerPadding - width : fillBox.innerPadding
            border.width: 0
            property color color1: {
                if (pCtrl.isHue)
                    return pCtrl.channelColor;
                return Qt.alpha(pCtrl.channelColor, 0.2);
            }
            property color color2: pCtrl.channelColor

            BasicColorBehavior on color1 {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicColorBehavior on color2 {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicNumberBehavior on width {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicNumberBehavior on height {
                enabled: pCtrl.animationReallyEnabled
            }

            gradient: Gradient {
                orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
                stops: [
                    GradientStop {
                        position: root.vertical ? 0.9 : 0.1
                        color: filler.color1
                    },
                    GradientStop {
                        position: root.vertical ? 0.1 : 0.9
                        color: filler.color2
                    }
                ]
            }//gradient
            states: [
                State {
                    when: root.horizontal
                    PropertyChanges {
                        filler.y: fillBox.innerPadding
                        filler.width: (fillBox.width - fillBox.innerPadding * 2) * root.position
                        filler.height: fillBox.height - fillBox.innerPadding * 2
                    }
                },
                State {
                    when: root.vertical
                    PropertyChanges {
                        filler.width: fillBox.width - fillBox.innerPadding * 2
                        filler.height: (fillBox.height - fillBox.innerPadding * 2) * root.position
                        filler.y: fillBox.height - fillBox.innerPadding - filler.height
                    }
                }
            ]//states
        }//filler
    }//contentItem

    SmartObject {
        id: pCtrl
        // side = 法向可用尺寸（水平=可用高、垂直=可用宽），透明手柄边长基准
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property bool isHue: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
        // 播种完成前填充动画关闭（初始定位无动画）
        property bool seedDone: false
        readonly property bool animationReallyEnabled: seedDone && root.animationEnabled && !root.pressed

        //通道标识色
        property color channelColor: {
            switch (root.channel) {
            case ColorNameHQ.HSVSaturation:
                return Qt.hsva(ColorNameHQ.clampChannelRange(root.colorAssistant.hsvHueF), 1, root.colorAssistant.hsvValueF, 1);
            case ColorNameHQ.HSLSaturation:
                return Qt.hsla(ColorNameHQ.clampChannelRange(root.colorAssistant.hslHueF), 1, root.colorAssistant.hslLightnessF, 1);
            case ColorNameHQ.HSVHue:
                return Qt.hsva(root.position, 1, 1, 1);
            case ColorNameHQ.HSLHue:
                return Qt.hsla(root.position, 1, .5, 1);
            }

            return ColorNameHQ.channelColor(root.channel);
        }

        // 动态属性名桥（channelNameF 为运行时字符串，QML 属性无法动态寻址）
        PropertyProxy {
            id: proxy
            target: root.colorAssistant
            property: ColorNameHQ.channelNameF(root.channel)
        }

        // 读方向：越界 hue（<0 无色相）不写——显示保持最后位置，
        // 且避免写方向 sat-bump 回环抬回 0.001
        Connections {
            target: proxy
            function onValueChanged() {
                const v = proxy.value;
                if (v >= 0 && v <= 1)
                    root.value = v;
            }
        }

        // 写方向：裁剪 [0,1]（越界仅外部程序写入）+ sat-bump
        Connections {
            target: root
            function onValueChanged() {
                const v = ColorNameHQ.clampChannelRange(root.value);
                if (v !== root.value) {
                    root.value = v;
                    return;
                }
                pCtrl.writeChannel(v);
            }
        }

        // sat-bump：hue 通道 + 无色相色 → 先写 sat 0.001 再写 hue
        //（sat=0 时色相无意义，直接写 hue 不产生预期颜色）
        function writeChannel(v) {
            if (root.channel === ColorNameHQ.HSVHue && root.colorAssistant.hsvHueF < 0)
                root.colorAssistant.hsvSaturationF = 0.001;
            else if (root.channel === ColorNameHQ.HSLHue && root.colorAssistant.hslHueF < 0)
                root.colorAssistant.hslSaturationF = 0.001;
            proxy.value = v;
        }
    }//pCtrl

    Component.onCompleted: {
        // 播种：从 assistant 现读真实通道值（越界跳过）；随后解锁填充动画
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
