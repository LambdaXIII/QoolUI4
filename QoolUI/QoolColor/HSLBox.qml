// HSLBox：HSL 二维取色表面公开组件（v4 新设计——单向链架构，对齐 HSVWheel）。
//
// 单向链架构（核心——无"光标↔值"双向绑定）：
//   鼠标事件 → setValues() → sat/ltn 数据 → position(sat,ltn) → 光标定位
// - 输入层：矩形平面响应鼠标，setValues() 把坐标裁剪后经映射转 sat/ltn
//   写 assistant。交互只写 sat/ltn，不写 hue（hue 由外部/联动驱动，
//   取现锚值——hue 恒合法，无色相由 sat/ltn 判定）。
// - 呈现层：光标是值的可视化（position(sat,ltn) 纯函数派生），非被拖动对象。
// - 平面与光标独立消费同一数据源（assistant），互不直连。
//
// 写入钳制两路（值合法，非坐标 clamp）：
// - 交互路径：保留 HSLSurface 既有映射（Qore.bound 矩形裁剪 →
//   saturationAt = x/w、lightnessAt = 1 - y/h）。
// - 接口路径：hue 越界归一化正模到 [0,1)（-0.5 → 0.5、1.5 → 0.5；hue 恒
//   合法，无色相由 sat/ltn 判定）；sat/ltn clamp [0,1]。
//
// 交互契约裁剪：无 defaultValue/reset、双击无定义行为（对齐 HSVWheel）。
// 注意：与 HSVWheel 不同，本件命中域无圆环钳制——矩形内直接裁剪
// （clamp），映射是线性平面；reset 语义不保留。

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
    // 接口层写入各有钳制语义（见文件头写入钳制两路）。
    property real hue: 0
    property real saturation: 0
    property real lightness: 1

    property real cursorSize: 22
    // 交互态（转发 InteractingArea——宿主可读拖动态，光标展开/动画门控）。
    readonly property bool userInteracting: area.userInteracting

    // 几何重定位：尺寸变化后光标中心不再对应旧坐标（症状 5）——事件驱动
    // 重算（updateCursor 幂等，绑定回写破坏约束下不可用绑定）。
    onWidthChanged: area.updateCursor()
    onHeightChanged: area.updateCursor()

    // —— HSL 平面表面（HSLSurface _private——色相×饱和度 + 明度三层叠加，
    // 映射数学见其文件头）。hslHue 决定平面色相，经 assistant.hslHueF 驱动。
    HSLSurface {
        id: surface
        hslHue: root.colorAssistant.hslHueF
        anchors.fill: parent
    }

    // —— 交互区：命中域为整个矩形（不设 containmentMask——矩形全命中，
    // 鼠标在矩形内直接裁剪，与 HSVWheel 的圆环钳制不同，旧 HSLBox 行为保留）。
    InteractingArea {
        id: area

        // 交互映射：坐标裁剪 → sat/ltn → 原子写 assistant（hue 取现锚值，
        // 恒合法——无色相时也记住 hue，拉起 ltn/sat 后恢复）。
        // 交互层不经接口属性（saturation/lightness）中转——直接写数据源。
        function setValues() {
            let xx = Qore.bound(0.0, mouseX, area.width);
            let yy = Qore.bound(0.0, mouseY, area.height);
            let p = Qt.point(xx, yy);
            let sat = surface.saturationAt(p);
            let ltn = surface.lightnessAt(p);
            root.colorAssistant.hslF = [root.colorAssistant.hslHueF, sat, ltn];
        }

        // 光标定位（事件驱动——CenterPlacer 回写破坏绑定，禁止绑定 centerx）
        function updateCursor() {
            const p = surface.position(root.colorAssistant.hslSaturationF, root.colorAssistant.hslLightnessF);
            centerer.centerx = p.x;
            centerer.centery = p.y;
        }

        onPressed: {
            // 补置 userInteracting（覆写 onPressed 覆盖了 InteractingArea
            // 内部 onPressed 的置位——不补则 userInteracting 恒 false、
            // onPositionChanged 拖动映射失效）。
            area.userInteracting = true;
            setValues();
        }
        onPositionChanged: {
            if (area.userInteracting)
                setValues();
        }

        // —— 光标（值的可视化，非拖动对象）：定位单向派生自数据源。
        // 事件驱动定位：CenterPlacer 回写会破坏 QML 绑定 → centerx/centery
        // 禁止绑定，由 updateCursor() 显式赋值（assistant 通道信号触发，见
        // root 级 Connections）。

        CrystalCursor {
            id: cursor
            property bool seedDone: false
            animationEnabled: seedDone && root.animationEnabled && !area.userInteracting
            width: root.cursorSize
            height: root.cursorSize
            objectName: "hslBoxCursor"  // 测试定位锚（几何重定位断言）

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
            function onSaturationChanged() {
                valueLatch.trigger();
            }
            function onLightnessChanged() {
                valueLatch.trigger();
            }
        }
    }

    // —— 读方向：assistant 通道 → 接口属性（外部改色/联动/程序写入）。
    // 读数恒合法（锚恒 ∈[0,1)，无 -1）——直接回写。
    Connections {
        target: root.colorAssistant
        function onHslHueFChanged() {
            root.hue = root.colorAssistant.hslHueF;
        }
        function onHslSaturationFChanged() {
            root.saturation = root.colorAssistant.hslSaturationF;
        }
        function onHslLightnessFChanged() {
            root.lightness = root.colorAssistant.hslLightnessF;
        }
    }

    // —— 光标定位驱动：assistant 通道变化 → 事件驱动更新光标位置。
    // （绑定会被 CenterPlacer 回写破坏——事件驱动是定案，勿改回绑定。）
    Connections {
        target: root.colorAssistant
        function onHslSaturationFChanged() {
            area.updateCursor();
        }
        function onHslLightnessFChanged() {
            area.updateCursor();
        }
    }

    // —— 写方向：接口属性 → assistant 通道（外部程序直写/联动）。
    // 钳制：hue 越界（<0 无色相或 NaN）不写——显示保持最后合法位置；
    // hue>1 归一化取模（% 1，对齐 setHslF 循环等价）；sat/ltn clamp [0,1]；
    // NaN 不写（防御——不污染通道）。同值写入 → assistant 相等守卫无环。
    Connections {
        target: root
        function onHueChanged() {
            if (Number.isNaN(root.hue))
                return;
            // hue 是圆周量 [0,1)：越界归一化正模（1.5 → 0.5、-0.5 → 0.5），
            // 对齐 assistant 锚归一化——hue 恒合法、无色相由 sat/ltn 判定
            const v = ((root.hue % 1) + 1) % 1;
            if (v !== root.hue)
                root.hue = v;
            else
                // 归一化回写（再入收敛——同值守卫无环）
                root.colorAssistant.hslHueF = v;
        }
        function onSaturationChanged() {
            const v = Math.max(0, Math.min(1, root.saturation));
            if (Number.isNaN(v))
                return;
            if (v !== root.saturation)
                root.saturation = v;
            else
                // clamp 回写接口属性（再入收敛——同值守卫无环）
                root.colorAssistant.hslSaturationF = v;
        }
        function onLightnessChanged() {
            const v = Math.max(0, Math.min(1, root.lightness));
            if (Number.isNaN(v))
                return;
            if (v !== root.lightness)
                root.lightness = v;
            else
                // clamp 回写接口属性（再入收敛——同值守卫无环）
                root.colorAssistant.hslLightnessF = v;
        }
    }

    // 播种：从 assistant 现读真实通道值（assistant 观察已建立——此处
    // completeCreate 后 target 绑定求值）。hue 越界（无色相）跳过——
    // 保持默认 0（hue 0≡0 循环等价）；写回同值 → assistant 相等守卫无环。
    Component.onCompleted: {
        root.lightness = root.colorAssistant.hslLightnessF;
        root.saturation = root.colorAssistant.hslSaturationF;
        root.hue = root.colorAssistant.hslHueF;  // 恒合法（锚 ∈[0,1)）
        // 初始定位延迟到事件循环下一轮：本组件内 CenterPlacer 的初始 resync
        // 在本组件 onCompleted 之后才执行（QML 完成时序），立即调用时 centery
        // 与 position 目标同值 → 同值守卫吞掉首次写入 → 光标 y 错位；resync
        // 后调用则写入必然生效（幂等，重复调用无害）。
        Qt.callLater(function () {
            area.updateCursor();
            cursor.seedDone = true;
        });
    }
}
