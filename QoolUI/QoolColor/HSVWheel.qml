// HSVWheel：HSV 二维取色表面公开组件（v4 新设计——单向链架构）。
//
// 定位：Qool.Color 模块公开一级组件（沿用 v3 名字，不改名），独立可复用的
// HSV 取色表面：圆盘响应鼠标取色（hue/saturation），value 影响圆盘压暗层。
// 旧 `_private/HSVWheel.qml` 为 v3 迁移临时载体，仅作参考基线（交互手感
// 逐点保留）；本件为 v4 正式组件，接口/语义按 v4 设计哲学重新定义。
//
// 单向链架构（核心——无"光标↔值"双向绑定）：
//   鼠标事件 → setValues() → hue/sat 数据 → position(hue,sat) → 光标定位
//                                  ↓
//                             → value 数据 → 圆盘压暗层
// - 输入层：圆盘响应鼠标，setValues() 把坐标经映射转 hue/sat 写 assistant。
//   交互写两个值**同时生效**（二维原子动作，不拆一维链投影——避免中间态
//   时序问题）。交互只写 hue/sat，不写 value（value 由外部/联动驱动）。
// - 呈现层：光标是值的可视化（position(hue,sat) 纯函数派生），非被拖动对象；
//   圆盘压暗层同理从数据派生。
// - 圆盘与光标独立消费同一数据源（assistant），互不直连。
//
// 写入钳制两路（值合法，非坐标 clamp）：
// - 交互路径：保留 hueAt / saturationAt 既有钳制（hueAt 返回 [0,1)、
//   saturationAt clamp [0,1]——圆外点击经 check_point 钳到圆周方向）。
// - 接口路径：hue/saturation/value 三个公开属性写入时钳制——hue 越界
//   （<0 无色相）不写进 assistant、显示保持最后合法位置（对齐
//   ColorChannelSlider 越界守卫——不 clamp 到 0 再写）；sat/value clamp [0,1]。
// - position 无坐标硬钳制（纯函数）——值域由写入层保证（值合法 → 光标
//   恒在圆内，外观保护靠值合法性而非坐标限制）。
//
// 交互契约裁剪：无 defaultValue/reset、双击无定义行为（对齐
// ColorChannelSlider/ColorChannelControl——旧双击 reset 不保留）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color
import "_private"

Item {
    id: root

    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    // 声明序首位（AGENTS MUST——统一声明序）。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 颜色数据源（默认自带——独立使用成立）。
    property ColorAssistant colorAssistant: ColorAssistant {}
    // 三个通道值（双向属性接口——外部写 → assistant；assistant 变 → 回读）。
    // 接口层写入各有钳制语义（见文件头写入钳制两路）。hue 越界（<0 无色相）
    // 不写、显示保持——读方向同守卫（assistant 为无色相时不回写、显示保持
    // 最后合法位置）。
    property real hue: 0
    property real saturation: 0
    property real value: 1
    // 交互态（转发 InteractingArea——宿主可读拖动态，光标展开/动画门控）。
    readonly property bool userInteracting: area.userInteracting

    // —— 圆盘表面（HSVSurface _private——色相环/饱和径向/明度压暗三层叠加，
    // 映射数学见其文件头）。value 经接口属性驱动压暗层（alpha = 1 - value
    // ——值合法域 [0,1] 由写入层保证）。
    HSVSurface {
        id: surface
        hsvValue: root.value
        anchors.fill: parent
        strokeColor: root.colorAssistant.recommendedForegroundColor
    }

    // —— 交互区（MouseArea 子类）：命中域为整个 surface（矩形）——圆外点击
    // 经 surface.check_point 钳到圆周方向，而非忽略（旧 v3 行为保留，勿改）。
    InteractingArea {
        id: area
        containmentMask: surface

        // 交互映射：坐标 → 钳制 → hue/sat → 两个同时写 assistant。
        // 交互层不经接口属性（hue/saturation）中转——直接写数据源，
        // 接口属性经读方向回读收敛（assistant 相等守卫断环）。
        function setValues() {
            const p = surface.check_point(Qt.point(mouseX, mouseY))
            const h = surface.hueAt(p)
            const s = surface.saturationAt(p)
            root.colorAssistant.hsvHueF = h
            root.colorAssistant.hsvSaturationF = s
        }

        onPressed: {
            // 补置 userInteracting（覆写 onPressed 覆盖了 InteractingArea
            // 内部 onPressed 的置位——不补则 userInteracting 恒 false、
            // onPositionChanged 拖动映射失效）。onReleased 基类未覆写、
            // 正常置 false。
            area.userInteracting = true
            setValues()
        }
        onPositionChanged: {
            if (area.userInteracting)
                setValues()
        }

        // —— 光标（值的可视化，非拖动对象）：定位单向派生自**数据源**
        // （assistant 通道——真实源，独立于接口属性的外部写入）。接口写入
        // 越界（hue<0）被守卫拒绝 → assistant 不变 → 光标保持；光标不依赖
        // root.hue 接口属性（显示保持由数据源承载）。centerx/centery 单向
        // 绑定，无 x/y 双向环。
        HSVWheelCursor {
            objectName: "wheelCursor"
            animationEnabled: root.animationEnabled
            currentColor: root.colorAssistant.solidColor
            userInteracting: root.userInteracting
            latchTarget: root.colorAssistant

            centerx: surface.position(root.colorAssistant.hsvHueF,
                                      root.colorAssistant.hsvSaturationF).x
            centery: surface.position(root.colorAssistant.hsvHueF,
                                      root.colorAssistant.hsvSaturationF).y
        }
    }

    // —— 读方向：assistant 通道 → 接口属性（外部改色/联动/程序写入）。
    // hue 越界（<0 无色相）不回写——显示保持最后合法位置（对齐
    // ColorChannelSlider 越界守卫）。sat/value 域合法直接回写。
    Connections {
        target: root.colorAssistant
        function onHsvHueFChanged() {
            const v = root.colorAssistant.hsvHueF
            if (v >= 0 && v <= 1)
                root.hue = v
        }
        function onHsvSaturationFChanged() {
            root.saturation = root.colorAssistant.hsvSaturationF
        }
        function onHsvValueFChanged() {
            root.value = root.colorAssistant.hsvValueF
        }
    }

    // —— 写方向：接口属性 → assistant 通道（外部程序直写/联动）。
    // 钳制：hue 越界（<0 无色相或 NaN）不写——显示保持最后合法位置
    // （不 clamp 到 0 再写——显示保持语义）；sat/value clamp [0,1]；
    // NaN 不写（防御——不污染通道）。同值写入 → assistant 相等守卫无环。
    Connections {
        target: root
        function onHueChanged() {
            if (Number.isNaN(root.hue))
                return
            if (root.hue < 0)
                return  // 无色相 marker：不写——显示保持最后合法位置
            // hue 是圆周量 [0,1)：越界 >1 归一化取模（1.5 → 0.5），
            // 对齐 QColor::setHsvF 的循环等价存储——1 ≡ 0、2 ≡ 0
            const v = root.hue % 1
            if (v !== root.hue)
                root.hue = v  // 归一化回写（再入收敛——同值守卫无环）
            else
                root.colorAssistant.hsvHueF = v
        }
        function onSaturationChanged() {
            const v = Math.max(0, Math.min(1, root.saturation))
            if (Number.isNaN(v))
                return
            if (v !== root.saturation)
                root.saturation = v  // clamp 回写接口属性（再入收敛——同值守卫无环）
            else
                root.colorAssistant.hsvSaturationF = v
        }
        function onValueChanged() {
            const v = Math.max(0, Math.min(1, root.value))
            if (Number.isNaN(v))
                return
            if (v !== root.value)
                root.value = v  // clamp 回写接口属性（再入收敛——同值守卫无环）
            else
                root.colorAssistant.hsvValueF = v
        }
    }

    // 播种：从 assistant 现读真实通道值（assistant 观察已建立——此处
    // completeCreate 后 target 绑定求值）。hue 越界（无色相）跳过——
    // 保持默认 0（hue 0≡0 循环等价）；写回同值 → assistant 相等守卫无环。
    Component.onCompleted: {
        root.value = root.colorAssistant.hsvValueF
        root.saturation = root.colorAssistant.hsvSaturationF
        const h = root.colorAssistant.hsvHueF
        if (h >= 0 && h <= 1)
            root.hue = h
    }
}
