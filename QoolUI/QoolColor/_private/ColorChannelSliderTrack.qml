// 双色渐变轨道（Crystal 六边形 + from/to 端点渐变）。Hue 通道由
// TrackHue 覆写 gradient 为彩虹（渐变锚定几何单点维护于
// Colors.gradientAnchors——勿在别处重算）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color
import "ColorChannelSliderColors.js" as Colors

Item {
    id: root

    anchors.fill: parent

    // 输入（ColorChannelSlider 注入）
    property bool animationEnabled: false
    property int channel: 0
    property ColorAssistant colorAssistant: null
    property bool horizontal: true
    property bool mirrored: false
    property real side: 25

    // 渐变覆写钩子：本件默认双色，TrackHue 覆写为彩虹
    property alias gradient: track.fillGradient

    // 锚定几何输入（Hue 特化覆写 gradient 时同源复用——轨道自身尺寸）
    readonly property real gradientWidth: track.width
    readonly property real gradientHeight: track.height

    QtObject {
        id: pCtrl
        readonly property real shrinkSize: Qore.bound(3, root.side * 0.25, 25)
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    Crystal {
        id: track
        objectName: "track"  // 测试定位
        width: parent.width - pCtrl.shrinkSize
        height: parent.height - pCtrl.shrinkSize
        x: pCtrl.halfShrinkSpace
        y: pCtrl.halfShrinkSpace
        // 兜底纯色（渐变通道失效时轨道仍可见）
        color: root.colorAssistant ? root.colorAssistant.solidColor
                                    : root.Style.accent
        // 描边 = assistant 推荐前景（0.5 阈值黑白自动对比）
        borderColor: root.colorAssistant
                     ? root.colorAssistant.recommendedForegroundColor
                     : ThemeHQ.recommendForeground(root.Style.accent)
        BasicColorBehavior on borderColor {
            enabled: root.animationEnabled
        }
        fillGradient: LinearGradient {
            // 锚定几何：水平 from 端 = 值小端（LTR 左、RTL 右）、垂直恒
            // from 底 → to 顶；坐标用轨道自身尺寸（收缩后切角 = 短边/2）
            readonly property var geo: Colors.gradientAnchors(
                                           track.width, track.height,
                                           root.horizontal, root.mirrored)
            x1: geo.x1
            y1: geo.y1
            x2: geo.x2
            y2: geo.y2
            GradientStop {
                position: 0
                color: Colors.fromColor(root.channel, root.colorAssistant)
            }
            GradientStop {
                position: 1
                color: Colors.toColor(root.channel, root.colorAssistant)
            }
        }
    }
}
