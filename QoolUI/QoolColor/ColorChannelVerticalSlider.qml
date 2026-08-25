import QtQuick
import QtQuick.Templates as T
import Qool
import QtQuick.Shapes
import Qool.Color
import Qool.Controls.Components
import "_private"

T.Slider {
    id: root

    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorHQ.HSLHue
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    orientation: Qt.Vertical

    // 默认 1（hue 1≡0 循环等价）；实际值由 onCompleted 播种。
    value: 1

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    background: Item {
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        // 值变化高亮锁存：写入 → 边框提亮一段窗口后回落。
        TimerLatch {
            id: justMovedLatch
            interval: Style.movementDuration * 2
            Connections {
                target: root
                function onValueChanged() {
                    justMovedLatch.trigger();
                }
            }
        }

        RectShape {
            id: trackShape
            objectName: "track"
            anchors.fill: parent
            radius: 4
            borderWidth: 1
            color: Qt.alpha(pCtrl.channelColor, 0.1)
            borderColor: justMovedLatch.active ? Qt.lighter(pCtrl.channelColor, 1.4) : pCtrl.channelColor
            BasicColorBehavior on borderColor {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicColorBehavior on color {
                enabled: pCtrl.animationReallyEnabled
            }

            fillGradient: {
                if (pCtrl.isHue)
                    return rainbow.createObject(trackShape);
                return null;
            }

            Component {
                id: rainbow
                RainbowGradient {
                    width: root.availableWidth
                    height: root.availableHeight
                    horizontal: root.horizontal
                    mirrored: root.mirrored
                    alpha: .25
                }
            }//rainbow
        }//rectShape
    }//background

    // 透明手柄：交互由模板控制层承担，栏上点击跳转。
    handle: Item {
        width: root.horizontal ? pCtrl.fillMin : pCtrl.side
        height: root.vertical ? pCtrl.fillMin / 2 : pCtrl.side
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

        // 几何/配色宿主：三态分派走 if-return；动画挂宿主，渲染件纯跟随
        // （勿直挂几何绑定——RectShape 曾求值异常）。
        DummyItem {
            id: fillHost

            x: {
                if (root.vertical)
                    return fillBox.innerPadding;
                if (root.mirrored)
                    return fillBox.width - fillBox.innerPadding - width;
                return fillBox.innerPadding;
            }
            y: {
                if (root.horizontal)
                    return fillBox.innerPadding;
                return fillBox.height - fillBox.innerPadding - height;
            }
            width: {
                const avail = fillBox.width - fillBox.innerPadding * 2;
                if (root.vertical)
                    return avail;
                return avail * root.position;
            }
            height: {
                const avail = fillBox.height - fillBox.innerPadding * 2;
                if (root.horizontal)
                    return avail;
                return Math.max(avail * root.position, pCtrl.fillMin);
            }

            BasicNumberBehavior on width {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicNumberBehavior on height {
                enabled: pCtrl.animationReallyEnabled
            }

            // color1 淡端（hue 时即主色）、color2 主色。
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

            readonly property color startColor: {
                if (root.vertical)
                    return color2;
                return color1;
            }
            readonly property color endColor: {
                if (root.vertical)
                    return color1;
                return color2;
            }

            // 渐变锚点：stop0 于 start、stop0.9 于 90%（末端平头）；竖直起点
            // 钉 min/2 视觉中部；水平随镜像换向。
            readonly property point gradStart: {
                if (root.vertical)
                    return Qt.point(0, pCtrl.fillMin / 2);
                if (root.mirrored)
                    return Qt.point(width, 0);
                return Qt.point(0, 0);
            }
            readonly property point gradEnd: {
                if (root.vertical)
                    return Qt.point(0, height);
                if (root.mirrored)
                    return Qt.point(0, 0);
                return Qt.point(width, 0);
            }
        }//fillHost

        // 填充条走 Shapes 路径（勿改回 Rectangle——其圆角渐变节点尺寸骤缩
        // 致 scene graph assert，Shapes 免疫）。
        RectShape {
            id: filler
            antialiasing: true
            x: fillHost.x
            y: fillHost.y
            width: fillHost.width
            height: fillHost.height
            radius: 2
            borderWidth: 0
            color: fillHost.color2

            fillGradient: LinearGradient {
                x1: fillHost.gradStart.x
                y1: fillHost.gradStart.y
                x2: fillHost.gradEnd.x
                y2: fillHost.gradEnd.y
                GradientStop {
                    position: 0
                    color: fillHost.startColor
                }
                GradientStop {
                    position: 0.9
                    color: fillHost.endColor
                }
            }//fillGradient
        }//filler
    }//contentItem

    SmartObject {
        id: pCtrl
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property bool isHue: root.channel === ColorHQ.HSVHue || root.channel === ColorHQ.HSLHue
        property bool seedDone: false
        readonly property bool animationReallyEnabled: seedDone && root.animationEnabled && !root.pressed

        // 最小高度＝轨道圆角直径（position=0 时保留极小渐变条）。
        readonly property real fillMin: trackShape.radius * 2

        property color channelColor: {
            switch (root.channel) {
            case ColorHQ.HSVSaturation:
                return Qt.hsva(ColorHQ.clampChannelRange(root.colorAssistant.hsvHueF), 1, root.colorAssistant.hsvValueF, 1);
            case ColorHQ.HSLSaturation:
                return Qt.hsla(ColorHQ.clampChannelRange(root.colorAssistant.hslHueF), 1, root.colorAssistant.hslLightnessF, 1);
            case ColorHQ.HSVHue:
                return Qt.hsva(root.position, 1, 1, 1);
            case ColorHQ.HSLHue:
                return Qt.hsla(root.position, 1, .5, 1);
            }

            return ColorHQ.channelColor(root.channel);
        }

        PropertyProxy {
            id: proxy
            target: root.colorAssistant
            property: ColorHQ.channelNameF(root.channel)
        }

        // 读方向：assistant 通道 → 接口属性。读数恒合法（锚恒 ∈[0,1)，无
        // -1）——守卫恒过，保留防御性；sat-bump 回环顾虑已随补丁退役。
        Connections {
            target: proxy
            function onValueChanged() {
                const v = proxy.value;
                if (v >= 0 && v <= 1)
                    root.value = v;
            }
        }

        Connections {
            target: root
            function onValueChanged() {
                const v = ColorHQ.clampChannelRange(root.value);
                if (v !== root.value) {
                    root.value = v;
                    return;
                }
                proxy.value = v;
            }
        }
    }//pCtrl

    Component.onCompleted: {
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
