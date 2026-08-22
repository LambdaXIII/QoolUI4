// ColorChannelVerticalSlider：竖直单通道滑块（T.Slider 平级——高定组件，
// 填充条样式）。
//
// 定位：Color 模块旧竖直通道滑块族（`_private/ChannelBar` 填充条 +
// ChannelSlider + 9 变体）的公开组件形态——原 ChannelBar 填充条视觉
// 迁移到 T.Slider 模板（拖动/键盘步进/点击跳转/RTL 由模板免费承载），
// 仿 ColorChannelSlider 设计（通用 channel 寻址 + 无条件链 + 契约裁剪 +
// 高定），样式保持原有填充条。与水平族 ColorChannelSlider 为兄弟组件
// （互不继承）——两条轨道视觉线有意并存（ADR-0018）。
//
// 高定边界（ADR-0018）：通道视觉（填充条/彩虹/边框/justMoved）完全
// 内化为组件语义，不暴露变体式外观接口；模板级 background/handle
// delegate 整体替换是唯一插拔口。交互契约裁剪：无 defaultValue/reset/
// 双击重置。
//
// 链模型（同源 ColorChannelSlider，改动须双处同步——ADR-0012 无状态
// 代理语义）：
// - `value ↔ PropertyProxy(assistant, channelNameF(channel)) ↔ 通道`
//   无条件双向——拖动写通道、外部改色（联动/程序）回写 value、
//   onCompleted 播种。
// - 同值守卫收敛（assistant 相等守卫 + T.Slider 同值守卫）——无拖动
//   互斥门控，模板拖动语义 + 同值守卫承担防抖。
// - sat-bump：hue 通道 + 无色相色（hue < 0）→ 先写对应 sat = 0.001 再
//   写 hue——sat=0 时色相无意义、直接写 hue 不产生预期颜色（旧 UX 契约）。
// - 限幅 [0,1]：模板拖动映射恒在界内，越界仅外部程序写入——裁剪可达
//   同等安全（旧 CycleBetweenEdges 环绕废弃）。
// - 越界 hue（< 0 无色相）不写 value：显示保持最后色相位置，且不合成
//   写入（否则 sat 拖到 0 会被 sat-bump 回环抬回 0.001）。
//
// 轨道：ColorChannelVerticalTrack 填充条视觉——非 hue 身份色填充、
// hue 彩虹原理式跟随（当前 sat/value 或 sat/lightness，类似
// HSVWheel/HSLBox 背景，与水平族 TrackHue 固定彩虹有意不同）+ 采样色
// 填充（对齐 Controls.Slider ColorMapper.colorAt 语义）。透明手柄
// side×side（25×25）——无可见视觉、无 hover 反馈，交互全由模板承担。
// orientation 默认 Qt.Vertical；填充条视觉为竖直定向（水平形态下填充
// 自底部语义未定义，文档明示）。

import QtQuick
import QtQuick.Templates as T
import Qool
import Qool.Color
import Qool.Controls.Components
import "_private"

T.Slider {
    id: root

    orientation: Qt.Vertical  // 默认竖直（T.Slider 默认 horizontal，须显式）

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    // 声明序首位（AGENTS MUST——统一声明序）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 通用通道寻址（ColorLiterals 枚举，对齐 ColorChannelSlider/ColorChannelEdit
    // ——无需 per-channel 变体文件）。
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
    // background 显式 implicit（竖直 25×150，与 ColorChannelSlider 的
    // orientation 交换同式）。
    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    SmartObject {
        id: pCtrl
        // 法向尺寸抽象：side = 法向可用尺寸（水平 = 可用高、垂直 = 可用
        // 宽）——手柄边长/定位全基于它（透明手柄 side×side，填充条无
        // 收缩让位，去 Crystal 收缩模型）。
        readonly property real side: root.horizontal ? root.availableHeight : root.availableWidth
        // 播种完成标记：完成前填充动画关闭（创建/播种期不动画——初始
        // 定位无动画惯例，照搬水平族 seedDone 语义）。
        property bool seedDone: false
    }

    // —— 轨道（background delegate）：Item 容器（尺寸经 Control 标准自动
    // 布局 = root − insets）+ 填充条视觉件（内部按 channel 分派 hue/非
    // hue，单件即可，无 Loader）。宿主可整换 background（模板插拔口）——
    // 高定边界内唯一外观覆写通道。
    background: Item {
        // implicit 随 orientation 交换（水平 150×25 ↔ 垂直 25×150）——
        // 对齐官方"垂直默认窄"惯例
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
        }
    }

    // —— 手柄（handle delegate）：透明 Item（side×side，无可见视觉、无
    // hover 反馈、无 cursorShape——原 ChannelBar 亦无；交互全由模板
    // 控制层承担，栏上其余位置点击跳转覆盖）。宿主可整换 handle（模板
    // 插拔口）。定位走 visualPosition（RTL 反转 + 垂直恒反转均随模板）；
    // 透明不可见，无 displayValue 平滑中间层需求。
    handle: Item {
        width: pCtrl.side
        height: pCtrl.side
        x: root.horizontal ? root.leftPadding + root.visualPosition * (root.availableWidth - width)
                           : root.leftPadding + (root.availableWidth - width) / 2
        y: root.horizontal ? root.topPadding + (root.availableHeight - height) / 2
                           : root.topPadding + root.visualPosition * (root.availableHeight - height)
    }

    // 通道寻址桥（动态属性名——channelNameF 为运行时字符串，QML 属性
    // 无法动态寻址）。target/property 为绑定、组件完成时才求值——显示
    // 与编辑基准不依赖引擎绑定求值序（ADR-0012 无状态代理 + ColorChannelEdit
    // 实证模式），本件链读写在 onCompleted/信号驱动下确定性执行。
    // 同源 ColorChannelSlider，改动须双处同步。
    PropertyProxy {
        id: proxy
        target: root.colorAssistant
        property: ColorNameHQ.channelNameF(root.channel)
    }

    // 读方向：assistant 通道 → root.value（外部改色/clamp 修正/联动）。
    // 越界值（hue < 0 无色相）不写 value——显示保持最后色相位置，且不
    // 合成写入（避免 sat-bump 回环：sat 拖到 0 → hue=-1 → 若 clamp 写 0
    // → 写方向 sat-bump 把 sat 抬回 0.001，拖零被撤销——实证路径）。
    // 同源 ColorChannelSlider，改动须双处同步。
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
    // 同源 ColorChannelSlider，改动须双处同步。
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
    // 颜色（旧 UX 契约，勿删/勿改为 0）。同源 ColorChannelSlider，改动
    // 须双处同步。
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
        // assistant 相等守卫无环。之后解锁填充动画（seedDone）。
        // 同源 ColorChannelSlider，改动须双处同步。
        const v = proxy.value;
        if (v >= 0 && v <= 1)
            root.value = v;
        pCtrl.seedDone = true;
    }
}
