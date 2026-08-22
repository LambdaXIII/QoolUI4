// 竖直单通道滑块（填充条样式，高定）。与水平族 ColorChannelSlider 兄弟
// 组件（互不继承）；链模型同源，改动须双处同步。
// 轨道：非 hue 身份色填充、hue 原理式彩虹背景 + 采样色填充（视觉细节
// 见 ColorChannelVerticalTrack）。

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color
import Qool.Controls.Components
import "_private"

T.Slider {
    id: root

    orientation: Qt.Vertical  // 默认竖直（T.Slider 默认 horizontal，须显式）

    // 声明序首位（AGENTS MUST）；父链继承，回退 Style.animationEnabled
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    property int channel: ColorNameHQ.HSLHue
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    // 默认 1 = hue 1≡0 循环等价；实际值由 onCompleted 播种
    value: 1

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    SmartObject {
        id: pCtrl
        // side = 法向可用尺寸（水平=可用高、垂直=可用宽），透明手柄边长基准
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        // 播种完成前填充动画关闭（初始定位无动画）
        property bool seedDone: false
    }

    background: Item {
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        ColorChannelVerticalTrack {
            anchors.fill: parent
            channel: root.channel
            colorAssistant: root.colorAssistant
            value: root.value
            pressed: root.pressed
            seedDone: pCtrl.seedDone
            animationEnabled: root.animationEnabled
            horizontal: root.horizontal
            mirrored: root.mirrored
        }
    }

    // 透明手柄（side×side）：无可见视觉、无 hover 反馈——交互全由模板
    // 控制层承担，栏上其余位置点击跳转。定位走 visualPosition。
    handle: Item {
        width: pCtrl.side
        height: pCtrl.side
        x: root.horizontal ? root.leftPadding + root.visualPosition * (root.availableWidth - width)
                           : root.leftPadding + (root.availableWidth - width) / 2
        y: root.horizontal ? root.topPadding + (root.availableHeight - height) / 2
                           : root.topPadding + root.visualPosition * (root.availableHeight - height)

        // NoButton：不拦截按压（模板拖动在手柄上仍有效）；指针随方向换
        MouseArea {
            objectName: "handleCursorArea"  // 测试定位
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }
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

    // 写方向：裁剪 [0,1]（越界仅外部程序写入）+ NaN 透传不写 + sat-bump
    Connections {
        target: root
        function onValueChanged() {
            const v = Math.max(0, Math.min(1, root.value));
            if (Number.isNaN(v))
                return;
            if (v !== root.value) {
                root.value = v;
                return;
            }
            writeChannel(v);
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

    Component.onCompleted: {
        // 播种：从 assistant 现读真实通道值（越界跳过）；随后解锁填充动画
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
