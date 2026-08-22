// ColorChannelSlider：通用单通道滑块（T.Slider 平级——高定组件）。
//
// 定位：Color 模块旧 `_private/ColorSlider.qml`（标题+数值输入行 + 轨道+
// 光标行）拆分工作——文字部分已由 ColorChannelEdit 承接，本件承接拖动
// 部分。与 Qool.Controls.Slider 为兄弟组件（同 T.Slider 模板交互 + Crystal
// 视觉语言家族，互不继承）：Slider 样式驱动、本件通道数据驱动——两套
// 视觉体系有意分叉（ADR-0013）。
//
// 高定边界（ADR-0013 Key Decision 2）：通道视觉（渐变/光标/描边）完全
// 内化为组件语义，不暴露变体式外观接口（fillGradient/strokeColor 等）；
// 模板级 background/handle delegate 整体替换是唯一插拔口。交互契约裁剪：
// 无 defaultValue/reset/双击重置（旧双击 = 回 defaultValue 的特化包袱）。
//
// 链模型（对齐 ColorChannelEdit——ADR-0012 无状态代理语义）：
// - `value ↔ PropertyProxy(assistant, channelNameF(channel)) ↔ 通道` 无条件
//   双向——拖动写通道、外部改色（联动/程序）回写 value、onCompleted 播种。
// - 同值守卫收敛（assistant 相等守卫 + T.Slider 同值守卫）——无拖动互斥
//   门控，模板拖动语义 + 同值守卫承担防抖。
// - sat-bump：hue 通道 + 无色相色（hue < 0）→ 先写对应 sat = 0.001 再写
//   hue——sat=0 时色相无意义、直接写 hue 不产生预期颜色（旧 UX 契约）。
// - 限幅 [0,1]：模板拖动映射恒在界内，越界仅外部程序写入——裁剪可达
//   同等安全（旧 CycleBetweenEdges 环绕废弃）。
// - 越界 hue（< 0 无色相）不写 value：显示保持最后色相位置，且不合成
//   写入（否则 sat 拖到 0 会被 sat-bump 回环抬回 0.001）。
//
// 轨道：按 channel 分派渐变（ColorChannelSliderTrack 双色 / TrackHue 彩虹，
// 端点语义见 ColorChannelSliderColors.js）；光标 ColorChannelSliderHandle
// 显示 solidColor 实色。orientation/RTL 由模板免费承载，渐变端锚定值增大
// 视觉端（ADR-0010 模式）。

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color
import Qool.Controls.Components
import "_private"

T.Slider {
    id: root

    orientation: Qt.Horizontal  // 显式锚定默认（对称竖直族显式声明——T.Slider 默认 horizontal）

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    // 声明序首位（AGENTS MUST——统一声明序）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 通用通道寻址（ColorLiterals 枚举，对齐 ColorChannelEdit——无需
    // per-channel 变体文件）。
    property int channel: ColorNameHQ.HSLHue
    // 通道数据源（默认自带——独立使用成立）。
    property ColorAssistant colorAssistant: ColorAssistant {
        color: Style.accent
    }

    // 交互契约裁剪：无 defaultValue/reset；value 初始默认 1（hue 1≡0
    // 循环等价无副作用——链在 onCompleted 从 assistant 播种，默认只影响
    // 播种前一瞬）。
    value: 1

    // 尺寸：标准 background 驱动——组件自写 implicit 公式（模板不自带），
    // background 显式 implicit（150×25，与 Qool.Controls.Slider 统一）；
    // 无 contentItem（前景在 handle 内、不占控件尺寸）。
    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    SmartObject {
        id: pCtrl
        // 法向尺寸抽象：side = 法向可用尺寸（水平 = 可用高、垂直 = 可用
        // 宽）——横竖对称、镜像无关（法向居中不随镜像变化）；手柄边长/
        // 收缩量/轨道收缩全部基于它（Qool.Controls.Slider 同款模型）。
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        readonly property real shrinkSize: Qore.bound(3, side * 0.25, 25)
        readonly property real halfShrinkSpace: shrinkSize / 2
        // Hue 通道（HSV/HSL 共用）→ 彩虹轨道特化
        readonly property bool hueChannel: root.channel === ColorNameHQ.HSVHue || root.channel === ColorNameHQ.HSLHue
        // 播种完成标记：完成前位置动画关闭（创建/播种期不动画——初始
        // 定位无动画惯例，ColorCursor initialized 同款延迟一帧）。
        property bool seedDone: false
    }

    // —— 轨道（background delegate）：Item 容器（尺寸经 Control 标准自动
    // 布局 = root − insets）+ Loader 按 channel 分派双色/彩虹轨道。宿主
    // 可整换 background（模板插拔口）——高定边界内唯一外观覆写通道。
    background: Item {
        // implicit 随 orientation 交换（水平 150×25 ↔ 垂直 25×150）——
        // 对齐官方"垂直默认窄"惯例
        implicitWidth: root.horizontal ? 150 : 25
        implicitHeight: root.horizontal ? 25 : 150

        Loader {
            anchors.fill: parent
            sourceComponent: pCtrl.hueChannel ? hueTrackComponent : baseTrackComponent
        }
    }

    Component {
        id: baseTrackComponent
        ColorChannelSliderTrack {
            channel: root.channel
            colorAssistant: root.colorAssistant
            horizontal: root.horizontal
            mirrored: root.mirrored
            side: pCtrl.side
            animationEnabled: root.animationEnabled
        }
    }

    Component {
        id: hueTrackComponent
        ColorChannelSliderTrackHue {
            channel: root.channel
            colorAssistant: root.colorAssistant
            horizontal: root.horizontal
            mirrored: root.mirrored
            side: pCtrl.side
            animationEnabled: root.animationEnabled
        }
    }

    // —— 光标（handle delegate）：CrystalCursor 内联接线（ADR-0016 收束
    // 光标骨架）——Crystal 菱形 + solidColor 实色 + 三态展开 + displayValue
    // 位置动画（拖动跟手、松手/外部改值平滑）。宿主可整换 handle（模板插拔口）。
    // —— 光标（handle delegate）：Item 壳（定位 + displayValue 位置动画 +
    // 三态归约 + 色源注入）+ 内联 CrystalCursor（ADR-0016 收束缩放骨架——
    // Crystal 菱形 + 实色 + 延迟缩放展开）。宿主可整换 handle（模板插拔口）。
    handle: Item {
        id: handleRoot
        // 边长 = 轨道法向（side）；delta = shrinkSize（常态贴轨道、展开
        // 顶出轨道但不出控件）
        width: pCtrl.side
        height: pCtrl.side

        // 定位（模板不注入——自写）：水平 x = leftPadding + displayValue ×
        // (availableWidth − width)、y 居中；垂直对调。displayValue 走
        // visualPosition（RTL 反转 + 垂直恒反转均随模板）。
        property real displayValue: root.visualPosition
        x: root.horizontal ? root.leftPadding + displayValue * (root.availableWidth - width)
                           : root.leftPadding + (root.availableWidth - width) / 2
        y: root.horizontal ? root.topPadding + (root.availableHeight - height) / 2
                           : root.topPadding + displayValue * (root.availableHeight - height)

        // 位置动画：displayValue 中间层 + Behavior 门控（pressed 关闭——
        // 拖动中跟手无滞后；positionAnimated 由宿主门控——创建/播种期不动画、
        // animationEnabled 关闭即跳变）
        BasicNumberBehavior on displayValue {
            enabled: pCtrl.seedDone && root.animationEnabled && !root.pressed
            duration: Style.movementDuration
        }

        // 值变化锁存（TimerLatch，上游脉冲→电平）：valueChanged 是瞬时
        // 事件——不经转换直接注入 expanded 只闪一帧。latch 把事件转成
        // 持续 expanded=true 窗口（interval = movementDuration×2 滑动窗口）
        // ——与 hover/pressed 共同驱动 expanded（hovered || pressed ||
        // latch.active），改值瞬间避免收缩再展开闪动。长保持归消费方：
        // CrystalCursor 内部另有下游防抖 latch（delay，短窗口通用），
        // 两层职责正交（脉冲→电平 vs 电平→防抖），不重复。
        TimerLatch {
            id: latch
            interval: Style.movementDuration * 2
            Connections {
                target: root
                function onValueChanged() {
                    latch.trigger()
                }
            }
        }

        // —— 光标基准件（CrystalCursor）：纯缩放（x/y 由 handleRoot 定位，
        // 根 footprint 恒定）；delta = shrinkSize；expanded = 三态或；色 =
        // 实色（solidColor）；动画门控透传。
        CrystalCursor {
            id: cursor
            anchors.fill: parent
            delta: pCtrl.shrinkSize
            animationEnabled: root.animationEnabled
            color: root.colorAssistant.solidColor
            expanded: hoverer.hovered || root.pressed || latch.active
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
        }
    }

    // 通道寻址桥（动态属性名——channelNameF 为运行时字符串，QML 属性
    // 无法动态寻址）。target/property 为绑定、组件完成时才求值——显示
    // 与编辑基准不依赖引擎绑定求值序（ADR-0012 无状态代理 + ColorChannelEdit
    // 实证模式），本件链读写在 onCompleted/信号驱动下确定性执行。
    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorNameHQ.channelNameF(root.channel)
    }

    // 读方向：assistant 通道 → root.value（外部改色/clamp 修正/联动）。
    // 越界值（hue < 0 无色相）不写 value——显示保持最后色相位置，且不
    // 合成写入（避免 sat-bump 回环：sat 拖到 0 → hue=-1 → 若 clamp 写 0
    // → 写方向 sat-bump 把 sat 抬回 0.001，拖零被撤销——实证路径）。
    Connections {
        target: proxy
        function onValueChanged() {
            const v = proxy.value;
            if (v >= 0 && v <= 1)
                root.value = v;
        }
    }

    // 写方向：root.value → 裁剪 [0,1] → sat-bump → proxy（assistant 通道）。
    // 同值守卫收敛（无拖动互斥门控——模板拖动语义 + 同值守卫承担防抖）。
    Connections {
        target: root
        function onValueChanged() {
            // 限幅：模板拖动映射恒在界内，越界仅外部程序写入——裁剪可达
            // 同等安全（旧环绕废弃）；NaN 透传不写（防御——不污染通道）。
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

    // sat-bump：hue 通道（HSV/HSL）且当前 hue < 0（无色相色）→ 先写对应
    // sat = 0.001 再写 hue——sat=0 时色相无意义、直接写 hue 不产生预期
    // 颜色（旧 UX 契约，勿删/勿改为 0）。
    function writeChannel(v) {
        if (root.channel === ColorNameHQ.HSVHue && root.colorAssistant.hsvHueF < 0)
            root.colorAssistant.hsvSaturationF = 0.001;
        else if (root.channel === ColorNameHQ.HSLHue && root.colorAssistant.hslHueF < 0)
            root.colorAssistant.hslSaturationF = 0.001;
        proxy.value = v;
    }

    Component.onCompleted: {
        // 播种：从 assistant 现读真实通道值（proxy 观察已建立——completeCreate
        // 时 target/property 绑定求值 + 初始同步 read）。越界（无色相 hue）
        // 跳过——保留默认 1（hue 1≡0 循环等价无副作用）；播种写回同值 →
        // assistant 相等守卫无环。之后解锁位置动画。
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
