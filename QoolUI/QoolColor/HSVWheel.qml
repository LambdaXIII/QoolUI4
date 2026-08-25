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
//   saturationAt clamp [0,1]——圆外点击经 check_point 钳到圆周方向）；
//   圆心 atan(0/0) 产生 NaN → setValues 有限性检查跳过本次写入（防御）。
// - 接口路径：hue/saturation/value 三个公开属性写入时钳制——hue 越界
//   归一化正模到 [0,1)（-0.5 → 0.5、1.5 → 0.5；hue 恒合法，无色相由
//   assistant 侧饱和度/明度判定）；sat/value clamp [0,1]。
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
    // 接口层写入各有钳制语义（见文件头写入钳制两路）。hue 恒合法（[0,1)，
    // 越界正模归一化）；读方向直接回写（assistant 读数恒合法，无 -1）。
    property real hue: 0
    property real saturation: .5
    property real value: .5

    property real cursorSize: 22
    // 交互态（转发 InteractingArea——宿主可读拖动态，光标展开/动画门控）。
    readonly property bool userInteracting: area.userInteracting

    // 几何重定位：尺寸变化后光标中心不再对应旧坐标（症状 5）——事件驱动
    // 重算（updateCursor 幂等，绑定回写破坏约束下不可用绑定）。
    onWidthChanged: area.updateCursor()
    onHeightChanged: area.updateCursor()

    // —— 圆盘表面（HSVSurface _private——色相环/饱和径向/明度压暗三层叠加，
    // 映射数学见其文件头）。value 经接口属性驱动压暗层（alpha = 1 - value
    // ——值合法域 [0,1] 由写入层保证）。
    HSVSurface {
        id: surface
        objectName: "hsvSurface"  // 测试定位锚（圆心 NaN/几何断言）
        hsvValue: root.value
        anchors.fill: parent
        strokeColor: root.colorAssistant.recommendedForegroundColor
    }

    // —— 交互区（MouseArea 子类）：命中域为整个 surface（矩形）——圆外点击
    // 经 surface.check_point 钳到圆周方向，而非忽略（旧 v3 行为保留，勿改）。
    InteractingArea {
        id: area
        containmentMask: surface

        // 交互映射：坐标 → 钳制 → hue/sat/value → 原子写 assistant。
        // 经 QList 原子写（单轮重算单轮广播）；交互层不经接口属性中转——
        // 直接写数据源，接口属性经读方向回读收敛（assistant 相等守卫断环）。
        // 圆心 atan(0/0) 的 hueAt 为 NaN → 有限性检查跳过本次写入（防御）。
        function setValues() {
            const p = surface.check_point(Qt.point(mouseX, mouseY));
            const h = surface.hueAt(p);
            if (!Number.isFinite(h))
                return;
            const s = surface.saturationAt(p);
            root.colorAssistant.hsvF = [h, s, root.value];
        }

        // 光标定位（事件驱动——CenterPlacer 回写破坏绑定，禁止绑定 centerx）
        function updateCursor() {
            const p = surface.position(root.colorAssistant.hsvHueF, root.colorAssistant.hsvSaturationF);
            centerer.centerx = p.x;
            centerer.centery = p.y;
        }

        onPressed: {
            // 补置 userInteracting（覆写 onPressed 覆盖了 InteractingArea
            // 内部 onPressed 的置位——不补则 userInteracting 恒 false、
            // onPositionChanged 拖动映射失效）。onReleased 基类未覆写、
            // 正常置 false。
            area.userInteracting = true;
            setValues();
        }
        onPositionChanged: {
            if (area.userInteracting)
                setValues();
        }

        CrystalCursor {
            id: cursor
            property bool seedDone: false
            animationEnabled: seedDone && root.animationEnabled && !area.userInteracting
            width: root.cursorSize
            height: root.cursorSize
            objectName: "hsvWheelCursor"  // 测试定位锚（几何重定位断言）

            delta: Qore.bound(4, root.cursorSize * 0.35, 15)

            color: root.colorAssistant.solidColor
            expanded: area.userInteracting || valueLatch.active || hoverer.hovered
            HoverHandler {
                id: hoverer
            }

            CenterPlacer {
                id: centerer
            }

            BasicNumberBehavior on x {
                enabled: cursor.animationEnabled
            }
            BasicNumberBehavior on y {
                enabled: cursor.animationEnabled
            }
        }
    }

    TimerLatch {
        id: valueLatch
        interval: root.Style.movementDuration * 2
        Connections {
            target: root
            function onHueChanged() {
                valueLatch.trigger();
            }
            function onSaturationChanged() {
                valueLatch.trigger();
            }
        }
    }

    // —— 读方向：assistant 通道 → 接口属性（外部改色/联动/程序写入）。
    // 读数恒合法（锚恒 ∈[0,1)，无 -1）——直接回写。
    Connections {
        target: root.colorAssistant
        function onHsvHueFChanged() {
            root.hue = root.colorAssistant.hsvHueF;
        }
        function onHsvSaturationFChanged() {
            root.saturation = root.colorAssistant.hsvSaturationF;
        }
        function onHsvValueFChanged() {
            root.value = root.colorAssistant.hsvValueF;
        }
    }

    // —— 光标定位驱动：assistant 通道变化 → 事件驱动更新光标位置。
    // （绑定会被 CenterPlacer 回写破坏——事件驱动是定案，勿改回绑定。）
    Connections {
        target: root.colorAssistant
        function onHsvHueFChanged() {
            area.updateCursor();
        }
        function onHsvSaturationFChanged() {
            area.updateCursor();
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
                return;
            // hue 是圆周量 [0,1)：越界归一化正模（1.5 → 0.5、-0.5 → 0.5），
            // 对齐 assistant 锚归一化——hue 恒合法、无色相由 sat/value 判定
            const v = ((root.hue % 1) + 1) % 1;
            if (v !== root.hue)
                root.hue = v;
            else
                // 归一化回写（再入收敛——同值守卫无环）
                root.colorAssistant.hsvHueF = v;
        }
        function onSaturationChanged() {
            const v = Math.max(0, Math.min(1, root.saturation));
            if (Number.isNaN(v))
                return;
            if (v !== root.saturation)
                root.saturation = v;
            else
                // clamp 回写接口属性（再入收敛——同值守卫无环）
                root.colorAssistant.hsvSaturationF = v;
        }
        function onValueChanged() {
            const v = Math.max(0, Math.min(1, root.value));
            if (Number.isNaN(v))
                return;
            if (v !== root.value)
                root.value = v;
            else
                // clamp 回写接口属性（再入收敛——同值守卫无环）
                root.colorAssistant.hsvValueF = v;
        }
    }

    // 播种：从 assistant 现读真实通道值（assistant 观察已建立——此处
    // completeCreate 后 target 绑定求值）。hue 越界（无色相）跳过——
    // 保持默认 0（hue 0≡0 循环等价）；写回同值 → assistant 相等守卫无环。
    Component.onCompleted: {
        root.value = root.colorAssistant.hsvValueF;
        root.saturation = root.colorAssistant.hsvSaturationF;
        root.hue = root.colorAssistant.hsvHueF;  // 恒合法（锚 ∈[0,1)）
        // 初始定位延迟到事件循环下一轮：本组件内 CenterPlacer 的初始 resync
        // 在本组件 onCompleted 之后才执行（QML 完成时序），立即调用时 centery
        // 恰为 0 与 position 目标同值 → 同值守卫吞掉首次写入 → 光标 y 错位；
        // resync 后调用则写入必然生效（幂等，重复调用无害）。
        Qt.callLater(function () {
            area.updateCursor();
            cursor.seedDone = true;
        });
    }
}
