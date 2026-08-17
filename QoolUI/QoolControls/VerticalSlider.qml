// Qool.Controls.VerticalSlider：Slider 的竖直化（独立实现——禁止 rotate）。
//
// 与 Slider 的设计差异（用户裁定 2026-08-10）：
//   - 参考轴交换：Slider 的尺寸/行程参考 root.height，竖直版参考
//     root.width——preferredWidth = root.width - bound(3, 宽度×25%, 25)；
//     轨道常态宽 = 手柄常态宽（贴斜边关系保持），展开占满控件宽度。
//   - 垂直移动：手柄沿 y 轴行程，**底部为 from**（值增大向上）——
//     y = topPadding + (1 - position) × (availableHeight - 手柄高)。
//   - 交互垂直化：T.Slider 的鼠标映射为水平语义（x → value，C++ 固定），
//     竖直布局下模板点击/拖动会错位——本组件用全区域 MouseArea（picker）
//     垂直映射（y → value：底部 from）取代模板交互（模板 press 被拦截
//     失效）；键盘 Up/Down → increase/decrease（模板 Left/Right 由基座保留）。
//   - 其余与 Slider 完全一致：水晶六边形模型（OctagonShape 特化）/
//     渐变内联/TimerLatch + NumberNotifier 锁存/动画门控/三心对齐/展开反馈。
//
// 视觉（默认 25 × 80）：轨道为瘦六边形（上下尖 + 左右直边——水晶 w<h
// 形态），渐变自底部 text → 顶部 color（底部 = from 端）。
//
// 公开属性：
//   - color：轨道渐变顶部色（默认 Style.accent——底部固定 Style.text）——
//     宿主换色即换整条轨道渐变 + Crystal 采样。
//   - animationEnabled：动画门控（父链继承，回退 Style.animationEnabled）。
//   - valueVelocity / justMoved：对外状态——值变化速率（值/秒）与"刚移动"
//     锁存窗口（500ms）。
//   - preferredWidth：水晶/轨道常态宽度（收缩态）——展开时水晶占满控件全宽。
//
// 注意（易误解）：
//   - handle delegate 必须自写 x/y（竖直行程公式见 handle 段）。
//   - 手柄展开态占满控件宽度（不超出边界）——clip 与否不影响反馈。
//   - 手柄 hover MouseArea 仅做光标反馈（NoButton——不拦截 picker 拖动）。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

T.Slider {
    id: root
    // 轨道渐变顶部色（底部固定 Style.text），默认 Style.accent。
    property color color: root.Style.accent
    // 值变化速率（值/秒，NumberNotifier 200ms 采样、有向、骤停归零）。
    readonly property real valueVelocity: notifier.velocity
    // "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。
    property bool justMoved: movementLatch.active
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 常态宽度：水晶手柄与轨道的常态（收缩）宽度——展开时水晶占满控件全宽（root.width）。
    readonly property real preferredWidth: root.width - Qore.bound(3, root.width * 0.25, 25)

    // 尺寸：反向排版策略——模板不自带 implicit 公式，root 直接给默认尺寸
    // （25 × 80 交换自 Slider 的 80 × 25），background 基于 root 布局（自动
    // fill 控件——切角/渐变锚定绑定 track 自身尺寸，随 root 缩放）——不依赖
    // implicitBackground* 的传递链（曾致高度恒 0；交互恢复实测于本策略）
    implicitWidth: 25
    implicitHeight: 80

    // —— 逻辑件：程序化变更锁存（NumberNotifier 采样 → TimerLatch 激活）——
    NumberNotifier on value {
        id: notifier
        interval: 200
    }

    TimerLatch {
        id: movementLatch
        interval: 500
        Connections {
            target: root
            function onValueChanged() {
                movementLatch.trigger();
            }
            function onValueVelocityChanged() {
                if (root.valueVelocity > 0)
                    movementLatch.trigger();
            }
        }
    }

    // —— 垂直交互（picker）：T.Slider 鼠标映射为水平语义（x → value，C++
    // 固定），竖直布局下模板点击/拖动错位——全区域 MouseArea 垂直映射取代
    // （y → value：底部 = from；模板 press 被拦截失效，pressed 反馈改由
    // picker 承担——见手柄 encountered）。hoverEnabled false 不抢手柄光标
    MouseArea {
        id: picker
        anchors.fill: parent
        // z 提升确保 press 命中（手柄内 NoButton MouseArea 之上；hoverEnabled
        // false 不抢 hover 光标）；enabled 跟随 root——disabled 时不响应
        z: 1
        enabled: root.enabled
        onPressed: (m) => {
            root.forceActiveFocus(); // 点击聚焦——键盘步进可用（模板行为）
            root.value = root.from + (1 - m.y / height) * (root.to - root.from)
        }
        onPositionChanged: (m) => {
            if (pressed)
                root.value = root.from + (1 - m.y / height) * (root.to - root.from)
        }
    }

    // 键盘：Up/Down 步进（值增大向上——底部 from）；Left/Right 模板行为保留
    Keys.onUpPressed: root.increase()
    Keys.onDownPressed: root.decrease()

    // —— 轨道（瘦六边形）：Crystal 组件（六边形模型——与手柄同模型、斜边
    // 斜率一致天然对齐；OctagonShape 双层模型——QoolBoxGadget 半平面交集
    // 下切角极限形态合法，Crystal 即 cut = shortEdge/2 特化）。显式绑定控件
    // 尺寸（覆盖 Crystal 的默认 20×20——background 自动 fill 在 Crystal 有
    // 尺寸绑定时未生效，曾致轨道缩成 20×20 菱形在左上角）。轨道恒为常态
    // 宽度（preferredWidth，不随展开变）+ 水平居中——三心对齐（水晶中心 =
    // 轨道中心 = 控件中心，水晶常态与轨道同宽贴斜边；展开时水晶顶出轨道
    // 但不出控件）
    background: Crystal {
        id: track
        width: root.preferredWidth
        height: root.height
        x: (root.width - width) / 2
        // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
        color: root.color
        fillGradient: LinearGradient {
            // 渐变内联默认（VerticalSlider 不再暴露 fillGradient——v4 收缩
            // 裁定，换色走 color 属性）：竖直渐变自底部 text → 顶部 color
            // （底部 = from 端）；锚定切角内侧（v3 渐变锚点语义）——与 Crystal
            // 中心行程对齐（colorAt(position) 精确采样——见文件头注释的数学）；
            // 坐标用 track 局部尺寸（轨道收缩后切角 = track.width/2）
            x1: track.width / 2
            y1: root.height - track.width / 2
            x2: track.width / 2
            y2: track.width / 2
            GradientStop {
                position: 0
                color: root.Style.text
            }
            GradientStop {
                position: 1
                color: root.color
            }
        }
    } //background

    // —— 手柄（Crystal 菱形）：尺寸跟随控件宽度（六边形对齐语义——见文件头）；
    // 展开反馈照 v3 ColorCursor 核心——
    handle: Item {
        id: handleRoot
        width: root.width
        height: width
        // handle delegate 须自写定位（模板不注入）——竖直行程公式：水平居中、
        // y 行程（底部 = from——position 0 → 底部）；Crystal 左上锚定，
        // 菱形中心 = 值位置（v3 语义：中心行程 [w/2, availH-w/2]，顶点贴端）
        x: root.leftPadding + (root.availableWidth - width) / 2
        y: root.topPadding + (1 - root.position) * (root.availableHeight - height)

        ColorMapper {
            id: colorMapper
            ColorMapperStop {
                position: 0
                color: root.Style.text
            }
            ColorMapperStop {
                position: 1
                color: root.color
            }
        }

        Crystal {
            id: crystal
            // 动画期间 CurveRenderer（原生 AA——展开缩放时小菱形边缘平滑且不重
            // 三角化），静止回退默认 GeometryRenderer（零额外成本）。仅手柄需要
            // （小尺寸亚像素毛躁；轨道为宽条像素充足——2026-08-10 裁定：全局
            // CurveRenderer 帧数降、layer MSAA 缩放性能降，按需切换折中）
            preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
            anchors.centerIn: parent
            // 仅 hover/光标反馈：NoButton 不拦截按压（picker 拖动在手柄上仍
            // 有效）；containmentMask 不设（Crystal 掩码已精确，手柄仍刻意
            // 不挂——NoButton 仅光标反馈、hover 域宽松）；disabled 时无反馈
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.enabled
                cursorShape: Qt.SizeVerCursor
            }

            HoverHandler {
                id: hoverer
                enabled: root.enabled
            }

            // 展开态占满 handle 区域（= 控件宽度，不超出边界）；常态 = 轨道
            // 宽度（preferredWidth——同收缩贴斜边；2026-08-10 裁定：原
            // "展开超出边界"刻意效果取消）。pressed 取自 picker（模板 press
            // 被 picker 拦截，root.pressed 恒 false）
            readonly property bool encountered: {
                return hoverer.hovered || picker.pressed || root.justMoved;
            }

            width: encountered ? root.width : root.preferredWidth
            height: width
            BasicNumberBehavior on width {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            // 常态色 = 轨道渐变在值位置的采样色（colorAt 精确——见文件头）；
            // 反馈仅展开（v3 的 pressed/锁存 lighter 提亮已裁定取消）
            color: colorMapper.colorAt(root.position)
            // Behavior 须声明在本对象内（on 作用于声明者自己的属性）
        }
    } //handle
}
