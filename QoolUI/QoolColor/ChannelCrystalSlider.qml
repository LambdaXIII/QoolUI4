// 链模型与 ChannelBoxSlider 同源，改动须双处同步。

import QtQuick
import QtQuick.Templates as T
import Qool
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

    orientation: Qt.Horizontal

    // 默认 1（hue 1≡0 循环等价）；实际值由 onCompleted 播种。
    value: 1

    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    background: Item {
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        Crystal {
            id: track
            objectName: "track"
            anchors.fill: parent
            anchors.margins: pCtrl.halfShrinkSpace
            color: root.colorAssistant ? root.colorAssistant.solidColor : root.Style.accent
            borderColor: root.colorAssistant ? root.colorAssistant.recommendedForegroundColor : ThemeHQ.recommendForeground(root.Style.accent)
            BasicColorBehavior on borderColor {
                enabled: pCtrl.animationReallyEnabled
            }
            // 动态创建渐变（createObject(track) 带 parent，归因实验实证无害）。
            fillGradient: {
                switch (root.channel) {
                case ColorHQ.HSLHue:
                case ColorHQ.HSVHue:
                    return rainbowGradient.createObject(track);
                case ColorHQ.HSLSaturation:
                case ColorHQ.HSVSaturation:
                case ColorHQ.HSLLightness:
                case ColorHQ.HSVValue:
                    return realGradient.createObject(track);
                }
                return simpleGradient.createObject(track);
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
                id: realGradient
                ChannelGradient {
                    horizontal: root.horizontal
                    width: root.availableWidth
                    height: root.availableHeight
                    channel: root.channel
                    mirrored: root.mirrored
                    toColor: root.colorAssistant.color
                }
            }//simple
            Component {
                id: rainbowGradient
                RainbowGradient {
                    width: root.availableWidth
                    height: root.availableHeight
                    horizontal: root.horizontal
                    mirrored: root.mirrored
                }
            }//rainbow

        }
    }//background

    handle: CrystalCursor {
        id: cursor
        width: pCtrl.side
        height: pCtrl.side

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

        BasicNumberBehavior on displayValue {
            enabled: pCtrl.animationReallyEnabled
            duration: Style.movementDuration
        }

        // 值变化锁存：避免改值瞬间收缩再展开闪动。
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
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property real shrinkSize: Qore.bound(3, side * 0.25, 25)
        readonly property real halfShrinkSpace: shrinkSize / 2
        // readonly property bool isHue: root.channel === ColorHQ.HSVHue || root.channel === ColorHQ.HSLHue
        property bool seedDone: false

        readonly property bool animationReallyEnabled: seedDone && root.animationEnabled && !root.pressed

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

        // 写方向：裁剪 [0,1] 后直写通道（hue 恒合法，无色相由 assistant
        // 侧判定——显式写 hue 落锚，无需 sat-bump 补偿）。
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
    }

    Component.onCompleted: {
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
