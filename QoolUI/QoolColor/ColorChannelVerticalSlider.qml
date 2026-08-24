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

        // 值变化高亮锁存：任何 value 写入（拖动/数值编辑/外部联动）→
        // 边框提亮一段窗口后回落（TimerLatch 上游脉冲→电平，家族惯用
        // 模式——Slider/CrystalCursor 同款；无公开状态，绑定直消费电平）
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
            objectName: "track"  // 测试定位
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

            // 常驻实例切换（勿回退 createObject 动态创建——绑定表达式
            // 返回的无 parent 渐变归 JS 引擎 GC 管辖，回收后 ShapePath/
            // 渲染侧仍持指针 → use-after-free 不确定性崩溃）。
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

        // 几何与配色宿主：三态分派（orientation × mirrored；竖直不受 RTL
        // 影响）一律走 if-return 绑定块；尺寸/颜色动画也挂在宿主上。
        // （勿把几何绑定直接挂回渲染件——RectShape 曾出现绑定求值异常。）
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
                // 最小高度：position=0 时保留一个轨道圆角直径的小条
                return Math.max(avail * root.position, pCtrl.fillMin);
            }

            BasicNumberBehavior on width {
                enabled: pCtrl.animationReallyEnabled
            }
            BasicNumberBehavior on height {
                enabled: pCtrl.animationReallyEnabled
            }

            // 渐变端点配色：color1 淡端（hue 时即主色）、color2 主色
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

            // 渐变线锚点（像素坐标）：stop 0 位于 start、stop 0.9 位于
            // 线段 90%（末端保留纯色平头）。竖直起点钉在 min/2——最小条
            // 的视觉中部；水平随镜像换向（值零侧为起点）。
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

        // 填充条 = RectShape 实现（勿改回 Rectangle：Rectangle 的圆角渐变
        // 节点在主轴尺寸骤缩时触发 scene graph 缺陷——qsgbasicinternal-
        // rectanglenode "index == vertexCount" assert；Shapes 路径已实验
        // 验证免疫，且与轨道 RectShape 同族）。几何/配色全部跟随宿主。
        RectShape {
            id: filler
            antialiasing: true
            x: fillHost.x
            y: fillHost.y
            width: fillHost.width
            height: fillHost.height
            radius: 2
            borderWidth: 0
            color: fillHost.color2   // 渐变失效兜底（纯浓色）

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
        // side = 法向可用尺寸（水平=可用高、垂直=可用宽），透明手柄边长基准
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property bool isHue: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
        // 播种完成前填充动画关闭（初始定位无动画）
        property bool seedDone: false
        readonly property bool animationReallyEnabled: seedDone && root.animationEnabled && !root.pressed

        // 填充条最小高度（仅竖直态生效）＝轨道圆角直径：position=0 时
        // 填充条不消失，保留一个圆角直径高的极小渐变条（2026-08-24
        // 外观设计定案，min 暂定 track radius × 2）
        readonly property real fillMin: trackShape.radius * 2

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
