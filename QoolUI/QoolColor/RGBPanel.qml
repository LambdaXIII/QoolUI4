// NOTE(迁移) v3 Qool.Color/RGBPanel.qml 迁移。
// 组合模式照迁：单行竖直通道滑块（GridLayout 一行五列）——
// 明度（ChannelSlider_Brightness，showBrightness 控制，默认隐藏）、
// 红/绿/蓝、透明度（ChannelSlider_Alpha，showAlpha 控制）。
// 替换点：Style.highlightColor → Style.highlight（见 T08/T10 style_mapping）。
// 交互照迁：各滑块竖直拖动（自下而上 0→1）、双击重置（通道默认值 1）、
//   滑块内嵌数值输入（x>1→/1000+限幅，滑块自身处理）。
// 与 v3 的刻意差异：无（v3 RGBPanel 本就不向滑块传 animationEnabled，
//   滑块各自取 Style.animationEnabled——v3 原样保留）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qool
import "_private"

/*!
    \qmltype RGBPanel
    \inqmlmodule Qool.Color
    \brief RGB 色彩空间面板（v3 RGBPanel 迁移）：明度/红/绿/蓝/透明度通道滑块行。

    单行竖直通道滑块组合（GridLayout 一行，横向铺满）：
    \list
    \li \l {ChannelSlider_Brightness}{ChannelSlider_Brightness} 明度通道
        （\c showBrightness 控制显隐，默认隐藏）。
    \li \l {ChannelSlider_Red}{ChannelSlider_Red}、\l {ChannelSlider_Green}{ChannelSlider_Green}、
        \l {ChannelSlider_Blue}{ChannelSlider_Blue} 三原色通道。
    \li \l {ChannelSlider_Alpha}{ChannelSlider_Alpha} 透明度通道（\c showAlpha 控制显隐）。
    \endlist

    \section1 交互（v3 照迁）

    \list
    \li 每个滑块竖直拖动改值（自下而上 0→1），通道值写 \c colorAssistant
        的 \c redF/greenF/blueF/alphaF（明度滑块走 \c hsvValueF）。
    \li 双击滑块重置为通道默认值 1（满通道）。
    \li 滑块内嵌数值输入（\l NumInput）：点击进入编辑，\c x > 1 时按
        \c x / 1000 处理并限幅到 [0, 1]（见下"输入约定"）。
    \endlist

    \section1 输入约定（易误解，特别说明）

    通道输入沿用 v3 数值约定：\b 输入 \c x > 1 时按 \c x / 1000 处理——
    允许直接键入 0..1000 的整数表示 0..1 的比例（如 \c 350 表示 0.35），
    结果限幅到 [0, 1]。这是 v3 面板行为，\b 不是 bug，勿"修复"为普通除法。
    实现收拢在 \l {NumInput::parseChannelValue}{NumInput.parseChannelValue}。

    \section1 默认状态自洽

    默认 \c colorAssistant 自带默认色
    \c {ColorAssistant { color: Style.highlight }}——独立使用（不注入）即成立。
    面板本身不设默认尺寸（v3 同），宿主决定宽高；滑块在网格中均分宽度。

    \section1 属性

    \qmlproperty ColorAssistant RGBPanel::colorAssistant
    颜色数据源（v3 同名 API 照迁）。默认自带 \c Style.highlight 的实例；
    宿主可注入共享 \l ColorAssistant（多面板同步同一实例）。

    \qmlproperty bool RGBPanel::showAlpha
    是否显示透明度通道滑块，默认 \c true。

    \qmlproperty bool RGBPanel::showBrightness
    是否显示明度通道滑块，默认 \c false（v3 默认隐藏）。

    \qmlproperty bool RGBPanel::animationEnabled
    动画总开关，默认继承父级或 \l {Style}{Style.animationEnabled}（v4 惯例）。
    注意：v3 本面板不向滑块显式传递此属性（滑块各自取
    \l {Style}{Style.animationEnabled}），v4 照迁，故本属性在本面板仅作
    API 面存在。
*/
GridLayout {
    id: root

    // 动画总开关：v3 同款传播（父级属性 → Style）。
    property bool animationEnabled: parent?.animationEnabled
                                    ?? Style.animationEnabled

    property bool showAlpha: true
    property bool showBrightness: false

    // 默认状态自洽：默认实例自带默认色，独立使用成立（v3 同构）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.highlight
    }

    columnSpacing: 5
    rowSpacing: 5

    ChannelSlider_Brightness {
        visible: root.showBrightness
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 0
    } //brightnessSlider

    ChannelSlider_Red {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 1
    } //redSlider

    ChannelSlider_Green {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 2
    } //greenSlider

    ChannelSlider_Blue {
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 3
    } //blueSlider

    ChannelSlider_Alpha {
        visible: root.showAlpha
        colorAssistant: root.colorAssistant
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.row: 0
        Layout.column: 4
    } //alphaSlider
}
