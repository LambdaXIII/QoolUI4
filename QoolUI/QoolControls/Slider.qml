// Qool.Controls.Slider：水晶六边形渐变轨道 + 菱形手柄的水平滑块
// （T.Slider 模板 API 兼容）。
//
// 完整契约（几何模型/交互反馈/属性/易误解点）见
// docs/reference/Qool.Controls/Slider.md。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

T.Slider {
    id: root
    // 轨道渐变右端色（左端固定 Style.text），默认 Style.accent。
    property color color: root.Style.accent
    // 值变化速率（值/秒，NumberNotifier 200ms 采样、有向、骤停归零）。
    readonly property real valueVelocity: notifier.velocity
    // "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。
    property bool justMoved: movementLatch.active
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    // 常态高度：水晶手柄与轨道的常态（收缩）高度——展开时水晶占满控件全高（root.height）。
    readonly property real preferredHeight: root.height - Qore.bound(3, root.height * 0.25, 25)

    // 尺寸：反向排版策略——模板不自带 implicit 公式，root 直接给默认尺寸
    // （80 × 25），background 基于 root 布局（自动 fill 控件——切角/渐变
    // 锚定绑定 track 自身尺寸，随 root 缩放）——不依赖 implicitBackground*
    // 的传递链
    implicitWidth: 80
    implicitHeight: 25

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

    // —— 轨道（六边形）：Crystal 组件（六边形模型——与手柄同模型、斜边
    // 斜率一致天然对齐；OctagonShape 双层模型——QoolBoxGadget 半平面
    // 交集下切角极限形态合法，Crystal 即 cut = shortEdge/2 特化）。显式
    // 绑定控件尺寸（覆盖 Crystal 默认 20×20——background 自动 fill 在
    // Crystal 有尺寸绑定时不生效）。轨道恒为常态高度（preferredHeight，
    // 不随展开变）+ 垂直居中——三心对齐（水晶中心 = 轨道中心 = 控件
    // 中心，水晶常态与轨道同高贴斜边；展开时水晶顶出轨道但不出控件）
    background: Crystal {
        id: track
        width: root.width
        height: root.preferredHeight
        y: (root.height - height) / 2
        // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
        color: root.color
        fillGradient: LinearGradient {
            // 渐变内联默认（Slider 不暴露 fillGradient 通道，换色走 color
            // 属性）：锚定切角内侧——与 Crystal 中心行程对齐
            // （colorAt(visualPosition) 精确采样）；坐标用 track 局部尺寸
            // （轨道收缩后切角 = track.height/2）
            x1: track.height / 2
            y1: track.height / 2
            x2: root.width - track.height / 2
            y2: track.height / 2
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

    // —— 手柄（Crystal 菱形）：尺寸跟随控件高度（六边形对齐语义）；展开
    // 反馈 = hover/按下/刚移动三态展开——
    handle: Item {
        id: handleRoot
        height: root.height
        width: height
        // handle delegate 须自写定位（模板不注入）——官方公式；Crystal 左上
        // 锚定，菱形中心 = 值位置（中心行程 [h/2, availW-h/2]，顶点贴端）
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

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
            // （小尺寸亚像素毛躁；轨道为宽条像素充足——全局 CurveRenderer 帧数
            // 降、layer MSAA 缩放性能降，按需切换折中）
            preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
            anchors.centerIn: parent
            // 仅 hover/光标反馈：NoButton 不拦截按压（模板拖动在手柄上仍有效）；
            // containmentMask 不设（Crystal 掩码已精确，手柄仍刻意不挂——
            // NoButton 仅光标反馈、hover 域宽松）；disabled 时无反馈
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.enabled
                cursorShape: Qt.SizeHorCursor
            }

            HoverHandler {
                id: hoverer
                enabled: root.enabled
            }

            // 展开态占满 handle 区域（= 控件高度，不超出边界）；常态 = 轨道
            // 高度（preferredHeight——同收缩贴斜边；原"展开超出边界"刻意
            // 效果已取消）
            readonly property bool encountered: {
                return hoverer.hovered || root.pressed || root.justMoved;
            }

            width: height
            height: encountered ? root.height : root.preferredHeight
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            // 常态色 = 轨道渐变在值位置的采样色（colorAt 精确）；反馈仅展开
            color: colorMapper.colorAt(root.visualPosition)
            // Behavior 须声明在本对象内（on 作用于声明者自己的属性）
        }
    } //handle
}
