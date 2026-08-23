// 通用单通道滑块（高定：通道视觉内化，唯一插拔口 = 模板级 background/handle）。
// 链模型与 ColorChannelVerticalSlider 同源，改动须双处同步。

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

    orientation: Qt.Horizontal  // 显式锚定默认（T.Slider 默认 horizontal）
    // 默认 1 = hue 1≡0 循环等价；实际值由 onCompleted 播种
    value: 1

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    background: Item {
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        Crystal {
            id: track
            objectName: "track"  // 测试定位
            anchors.fill: parent
            anchors.margins: pCtrl.halfShrinkSpace
            // 兜底纯色（渐变通道失效时轨道仍可见）
            color: root.colorAssistant ? root.colorAssistant.solidColor : root.Style.accent
            // 描边 = assistant 推荐前景（0.5 阈值黑白自动对比）
            borderColor: root.colorAssistant ? root.colorAssistant.recommendedForegroundColor : ThemeHQ.recommendForeground(root.Style.accent)
            BasicColorBehavior on borderColor {
                enabled: pCtrl.animationReallyEnabled
            }
            fillGradient: {
                if (pCtrl.isHue)
                    return rainbow.createObject();
                return simpleGradient.createObject();
            }

            Component {
                id: simpleGradient
                ChannelGradient {
                    horizontal: root.horizontal
                    width: root.availableWidth
                    height: root.availableHeight
                    channel: root.channel
                    mirrored: root.mirrored
                }
            }//simple

            Component {
                id: rainbow
                RainbowGradient {
                    width: root.availableWidth
                    height: root.availableHeight
                    horizontal: root.horizontal
                    mirrored: root.mirrored
                }
            }//rainbow

        }
    }//background

    // 手柄 = CrystalCursor 本体（ADR-0016 基准件，根即 handle——与
    // Qool.Controls.Slider 同构）：定位/锁存/光标形状内联实例（基准件契约
    // 裁剪——定位与长保持锁存归消费方）；footprint 恒定（缩放只作用内部
    // Crystal——定位锚不随缩放偏移）。
    handle: CrystalCursor {
        id: cursor
        width: pCtrl.side
        height: pCtrl.side

        // 定位走 visualPosition（RTL 反转 + 垂直恒反转均随模板）
        property real displayValue: root.visualPosition
        x: {
            if (root.horizontal)
                return root.leftPadding + displayValue * (root.availableWidth - width);
            return root.leftPadding + (root.availableWidth - width) / 2;
        }
        y: {
            if (root.horizontal)
                return root.topPadding + (root.availableHeight - height) / 2;
            return root.topPadding + displayValue * (root.availableHeight - height);
        }

        // 拖动中关闭平滑（跟手）；seedDone 前不动画
        BasicNumberBehavior on displayValue {
            enabled: pCtrl.animationReallyEnabled
            duration: Style.movementDuration
        }

        // 值变化锁存：valueChanged 瞬时事件 → 持续 expanded 窗口，
        // 避免改值瞬间收缩再展开闪动
        TimerLatch {
            id: crystalValueLatch
            interval: Style.movementDuration * 2
            Connections {
                target: proxy
                function onValueChanged() {
                    crystalValueLatch.trigger();
                }
            }
        }

        delta: pCtrl.shrinkSize
        animationEnabled: pCtrl.animationReallyEnabled
        color: root.colorAssistant.solidColor
        expanded: hoverer.hovered || root.pressed || crystalValueLatch.active
        enabled: root.enabled

        // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动在手柄上仍
        // 有效）；disabled 时无反馈
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            enabled: root.enabled
            cursorShape: root.horizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }

        HoverHandler {
            id: hoverer
            enabled: root.enabled
        }
    }//handle

    SmartObject {
        id: pCtrl
        // side = 法向可用尺寸（水平=可用高、垂直=可用宽），手柄边长/轨道收缩基准
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property real shrinkSize: Qore.bound(3, side * 0.25, 25)
        readonly property real halfShrinkSpace: shrinkSize / 2
        readonly property bool isHue: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
        // 播种完成前位置动画关闭（初始定位无动画）
        property bool seedDone: false

        readonly property bool animationReallyEnabled: seedDone && root.animationEnabled && !root.pressed

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
    }

    Component.onCompleted: {
        // 播种：从 assistant 现读真实通道值（越界跳过）；随后解锁位置动画
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
