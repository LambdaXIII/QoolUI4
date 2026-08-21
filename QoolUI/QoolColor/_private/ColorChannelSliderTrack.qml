// ColorChannelSliderTrack：通道滑块轨道（双色渐变基类——Crystal 六边形 +
// from/to 双色端点渐变 + 自动对比描边）。ColorChannelSlider 的 background
// delegate 内容件（经 Loader 分派：Hue 通道 → ColorChannelSliderTrackHue
// 彩虹覆写，其余 → 本件）。
//
// 渐变语义（数据决策，非术语）：端点色经 ColorChannelSliderColors.js
// fromColor/toColor 映射（RGB 黑→纯色、Value/Lightness 黑→白、CMYK 白→
// 纯色、Alpha 透明→当前实色、Sat 灰→纯 hue 色）；Hue 通道彩虹特化在
// TrackHue。
//
// 易误解点（勿改）
// - 渐变锚定几何（cut 切角 + 值增大视觉端 + 垂直 from 底→to 顶）在
//   Colors.gradientAnchors 单点维护——Hue 特化（覆写 gradient）经
//   gradientWidth/gradientHeight 同源复用，勿在别处重算。
// - gradient 属性是可覆写钩子（本件默认双色；TrackHue 覆写彩虹）——
//   仅供 _private 视觉族内部覆写；宿主级插拔口在模板 background/handle
//   delegate（整换），高定边界不暴露外观参数。
// - 描边 = assistant.recommendedForegroundColor（0.5 阈值黑白自动对比）
//   ——高定内化，不暴露。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color
import "ColorChannelSliderColors.js" as Colors

Item {
    id: root

    // 填充宿主 Loader（background delegate 内容件——尺寸经模板自动布局）
    anchors.fill: parent

    // 输入（ColorChannelSlider 注入——background delegate 内容契约）
    property bool animationEnabled: false
    property int channel: 0
    property ColorAssistant colorAssistant: null
    property bool horizontal: true
    property bool mirrored: false
    property real side: 25

    // 渐变覆写钩子：默认双色（本件）——TrackHue 覆写为彩虹。_private
    // 视觉族内部使用，宿主不可见（未注册进模块）。
    property alias gradient: track.fillGradient

    // 渐变锚定几何（Hue 特化覆写 gradient 时同源复用——轨道自身尺寸）
    readonly property real gradientWidth: track.width
    readonly property real gradientHeight: track.height

    QtObject {
        id: pCtrl
        // 收缩模型对齐 Qool.Controls.Slider：side = 法向尺寸、常态收缩量
        // bound(3, side×0.25, 25)、轨道收缩 + 法向居中——展开光标"顶出
        // 轨道但不出控件"三心对齐
        readonly property real shrinkSize: Qore.bound(3, root.side * 0.25, 25)
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    // 轨道（Crystal 六边形——cut = 短边/2 与旧六边形同形）：恒为常态
    // （不随展开变）+ 法向居中。objectName 供 QML 测试读取（轨道静态性
    // 是公开视觉契约——组件内部对象零暴露原则的测试例外，tst_slider
    // 同款惯例）。
    Crystal {
        id: track
        objectName: "track"
        width: parent.width - pCtrl.shrinkSize
        height: parent.height - pCtrl.shrinkSize
        x: pCtrl.halfShrinkSpace
        y: pCtrl.halfShrinkSpace
        // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
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
            // 锚定几何（Colors.gradientAnchors 单点维护——勿在此重算）：
            // 水平 from 端 = 值小端（LTR 左、RTL 右）、垂直恒 from 底 →
            // to 顶；坐标用 track 自身尺寸（收缩后切角 = 短边/2，与手柄
            // 中心行程一致）
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
