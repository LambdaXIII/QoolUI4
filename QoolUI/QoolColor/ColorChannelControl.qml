// ColorChannelControl：单通道「数值编辑 + 拖动调值」组合件（旧 ColorSlider
// 形态还原——Control 基座组合 ColorChannelEdit + ColorChannelSlider）。
//
// 定位：Color 模块旧 `_private/ColorSlider.qml`（标题+数值输入行 + 轨道+
// 光标行）拆分后，公开消费方需要旧单控件形态时的组合件。集束共有属性
// （animationEnabled/channel/colorAssistant/value/readOnly）外壳统一声明、
// 转发两子组件——宿主配置一个组件即得完整通道行，不必手动配对。
//
// 集束不变量：colorAssistant 为**单一共享实例**（外壳声明、两子组件链向
// 同一实例）——编辑与拖动始终作用于同一通道，value 经同一 assistant
// 收敛；任子组件落回自带默认 assistant 即分叉、集束失效。
//
// 纯封装：不暴露 edit/slider 子组件别名——插拔面由子组件自身承接
// （ColorChannelEdit displayItem、ColorChannelSlider 模板级
// background/handle），根层再开一层是 YAGNI 且会破坏集束不变量。
//
// value：外壳**自持** PropertyProxy ↔ assistant 双向链（独立第三投影，不
// alias 任一子组件 value——照 ColorChannelEdit 链模式：双向 Connections +
// onCompleted 播种）。两子组件各自链经同一 assistant 收敛，外壳 value 与
// 它们汇聚同值；子组件的越界 hue 显示差异（Edit 显示真实源、Slider 有
// 越界守卫）是既有行为，外壳不解决。

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qool
import Qool.Color

Control {
    id: root

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    // 声明序首位（AGENTS MUST——统一声明序）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 通用通道寻址（ColorLiterals 枚举，对齐子组件——无需 per-channel 变体）。
    property int channel: ColorNameHQ.HSLHue
    // 通道数据源（单一共享实例——集束不变量，见文件头）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }
    // 通道值（独立第三投影——PropertyProxy ↔ assistant 双向链，见下）。
    property real value
    // 编辑只读（转发 → ColorChannelEdit.readOnly → EditableText.readOnly：
    // 不启动编辑会话——点击/聚焦空转；滑块拖动保留）。
    property bool readOnly: false

    // 布局：编辑在上、滑块在下、两行等宽（fillWidth）、零间距——旧
    // ColorSlider 单控件形态。
    contentItem: ColumnLayout {
        spacing: 0

        ColorChannelEdit {
            Layout.fillWidth: true
            animationEnabled: root.animationEnabled
            channel: root.channel
            colorAssistant: root.colorAssistant
            readOnly: root.readOnly
        }

        ColorChannelSlider {
            Layout.fillWidth: true
            animationEnabled: root.animationEnabled
            channel: root.channel
            colorAssistant: root.colorAssistant
        }
    }

    // 通道寻址桥（同子组件——动态属性名：channelNameF 为运行时字符串，QML
    // 属性无法动态寻址；target/property 为绑定、组件完成时才求值）。
    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorNameHQ.channelNameF(root.channel)
    }

    // 读方向：assistant 通道 → root.value（外部改色/clamp 修正/联动——
    // 子组件链先收敛，本链同值回读）。
    Connections {
        target: proxy
        function onValueChanged() {
            root.value = proxy.value
        }
    }

    // 写方向：root.value（外部程序直写外壳 / 编辑收尾经子组件写
    // assistant → 本链同值回读收敛）→ proxy → assistant 通道。
    Connections {
        target: root
        function onValueChanged() {
            proxy.value = root.value
        }
    }

    // 播种：从 assistant 现读真实通道值（proxy 观察已建立——completeCreate
    // 时 target/property 绑定求值 + 初始同步 read）；NaN 防御（不写污染
    // 属性）。写回同值 → assistant 相等守卫无环。
    Component.onCompleted: {
        const v = proxy.value
        if (!Number.isNaN(v))
            root.value = v
    }
}
