// Qool.Controls.RangeHandle：区间滑块的范围逻辑容器（与 RangeSlider 配套，
// 可独立实例化）——区间全部逻辑（空间位置、三区域交互、surface 布局控制）
// 的单一归属。除 surface（纯外观）外一切行为止于此；宿主可继承本组件并
// 替换到 RangeSlider 的 rangeHandle 属性实现行为插拔。
//
// 三区域交互：左端区拖动 → firstMoved（改 first）、右端区拖动 →
// secondMoved（改 second）、中段区拖动 → rangeMoved（整体滑移，宿主换算
// 为值后 setValues 写入）；全部点击无操作。分区边界基于值几何（W =
// 控件高/2），不绑定 surface 实际尺寸——展开/常态下分区稳定一致。
//
// 值→位置映射不在此处（RangeHandle 收位置、发位置信号——保持纯逻辑容器
// 职责）；映射公式在 RangeSlider（其有 leftPadding/availableWidth 行程）。
//
// 完整契约（布局/插拔/交互/几何）见
// docs/reference/Qool.Controls/RangeHandle.md。

import QtQuick
import QtQuick.Shapes
import Qool

Item {
    id: root

    // —— 输入（宿主/RangeSlider 配套绑定）——
    /* first 端点位置（父级坐标）——surface 左端基准、左区拖动目标。 */
    property real firstPosition: 0
    /* second 端点位置（父级坐标）——surface 右端基准、右区拖动目标。 */
    property real secondPosition: 0
    /* surface 左右溢出量（默认 = preferredHeight/2——尖角溢出展示；宿主替换
       surface 后按需调整，如置 0 获得精确 fill——RangeHandle 不自动切换布局
       模式）。 */
    property real cutSize: root.preferredHeight / 2
    /* surface 常态高度（默认 = 控件高收缩公式——与 RangeSlider/Slider 家族
       一致）。 */
    property real preferredHeight: root.height - Qore.bound(3, root.height * 0.25, 25)
    /* 外部展开源（配套绑定 = 宿主 justMoved）——与内部 pressed/hovered
       合成 expanded。 */
    property bool externalExpanded: false
    /* surface 填充色（配套绑定 = 宿主 color）。 */
    property color color: root.Style.accent
    /* 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。 */
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    /* surface（外观插拔件）：默认 Crystal 前景——整体形状（左尖角 + 中段
       填充 + 右尖角），布局（x/y/width/height/color）由本组件统一施加
       （Binding——宿主替换任意 Item 即自动填充正确区间，无需自算值→位置
       映射）。surface 不自行响应值数据。 */
    property Item surface: Crystal {
        parent: root
        // 动画期间 CurveRenderer（原生 AA——展开缩放时形状边缘平滑），
        // 静止回退默认 GeometryRenderer（Slider 手柄同款折中）
        preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
        // 展开动画（surface 高度切换——本组件经 Binding 写 height；
        // Behavior 须声明在目标对象内——on 作用于声明者自己的属性）
        BasicNumberBehavior on height {
            enabled: root.animationEnabled
            duration: Style.transitionDuration
        }
    }

    // —— 信号（宿主换算为值；载荷 = 父级坐标位置/像素位移）——
    /* 左端拖动——新位置（已钳制：行程内且不越过 second）。 */
    signal firstMoved(real newPosition)
    /* 右端拖动——新位置（已钳制：行程内且不越过 first）。 */
    signal secondMoved(real newPosition)
    /* 中段拖动——本次位移（像素，本次事件相对上次事件）。 */
    signal rangeMoved(real delta)

    // —— 派生只读（surface 高度切换依据 / 区间中心）——
    /* 展开态：externalExpanded || 按下 || 悬停。 */
    readonly property bool expanded: root.externalExpanded || mouse.pressed || hover.hovered
    /* surface 高度：展开 = 控件全高、常态 = preferredHeight。 */
    readonly property real surfaceHeight: root.expanded ? root.height : root.preferredHeight
    /* 区间中心（三区域中间值之一——端点位置 + 区间中心，供自定义 surface
       或宿主感知分区）。 */
    readonly property real midPosition: (root.firstPosition + root.secondPosition) / 2

    // 三区域分区边界（值几何推导——W = 控件高/2；不绑定 surface 实际尺寸）
    readonly property real zoneWidth: root.height / 2

    // 隐式尺寸（独立实例化自洽——与 Slider 家族默认一致）
    implicitWidth: 80
    implicitHeight: 25

    // —— 分区判定与端点钳制（行程 [h/2, 宽-h/2]——两端可重合（退化区间），
    // 不越界）——
    function zoneAt(x) {
        if (x < root.firstPosition + root.zoneWidth)
            return "left"
        if (x < root.secondPosition - root.zoneWidth)
            return "mid"
        return "right"
    }
    function clampFirst(pos) {
        return Math.max(root.height / 2, Math.min(pos, root.secondPosition))
    }
    function clampSecond(pos) {
        return Math.max(root.firstPosition, Math.min(pos, root.width - root.height / 2))
    }

    // —— 交互（三区域拖动；全部点击无操作——按下只记录分区，拖动才发信号；
    // 按下取焦点——键盘经父链冒泡到宿主（模板 RangeSlider 键盘保留））——
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.SizeHorCursor
        property string zone: ""
        property real lastX: 0

        onPressed: m => {
            mouse.zone = root.zoneAt(m.x)
            mouse.lastX = m.x
            root.forceActiveFocus()
        }
        onPositionChanged: m => {
            if (!mouse.pressed || mouse.zone === "")
                return
            if (mouse.zone === "left")
                root.firstMoved(root.clampFirst(m.x))
            else if (mouse.zone === "right")
                root.secondMoved(root.clampSecond(m.x))
            else {
                const delta = m.x - mouse.lastX
                mouse.lastX = m.x
                if (delta !== 0)
                    root.rangeMoved(delta)
            }
        }
        onReleased: mouse.zone = ""
        onCanceled: mouse.zone = ""
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
    }

    // —— surface 布局控制（Binding——宿主替换 surface 时新实例同样受控）：
    // x = firstPosition − cutSize（尖角左溢）、width = 区间宽 + 2×cutSize、
    // y 垂直居中、height = surfaceHeight、color = 填充色（surface 无 color
    // 属性时不施加——外观完全自主的宿主替换件）；parent 显式挂（属性对象
    // 不自动成为声明对象的子项——QoolBGBox 同款约定）——
    Binding {
        target: root.surface
        property: "parent"
        value: root
    }
    Binding {
        target: root.surface
        property: "x"
        value: root.firstPosition - root.cutSize
    }
    Binding {
        target: root.surface
        property: "y"
        value: (root.height - root.surfaceHeight) / 2
    }
    Binding {
        target: root.surface
        property: "width"
        value: root.secondPosition - root.firstPosition + 2 * root.cutSize
    }
    Binding {
        target: root.surface
        property: "height"
        value: root.surfaceHeight
    }
    Binding {
        target: root.surface
        property: "color"
        value: root.color
        when: root.surface && root.surface.color !== undefined
    }
} //Item
