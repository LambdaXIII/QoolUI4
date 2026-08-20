// Qool.Controls.Slider：水晶六边形渐变轨道 + 菱形手柄的水平滑块
// （T.Slider 模板 API 兼容）。
//
// 结构：模板 handle（激活模板交互——点击跳转/拖动连续/键盘步进/倒置范围
// 免费）+ Crystal 渐变轨道（background，静态）+ handle 内前景 Crystal
// （hover/按下/值变化锁存展开动画）。轨道渐变与手柄采样色同源——换 color
// 即换整条视觉。
//
// 完整契约（几何模型/交互反馈/属性/易误解点）见
// docs/reference/Qool.Controls/Slider.md。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

T.Slider {
    id: root
    // 轨道渐变右端色（左端 = backgroundColor 75% 透明），默认 Style.accent。
    property color color: root.Style.accent
    // 轨道背景色（渐变左端以 75% 透明度渲染），默认 Style.buttonText。
    property color backgroundColor: Style.buttonText
    // 轨道描边色——基于 backgroundColor 自动对比推荐（宿主可单独覆盖）。
    property color borderColor: ThemeHQ.recommendForeground(backgroundColor)
    // 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 尺寸：标准 background 驱动——组件自写 implicit 公式（模板不自带），
    // background 显式 implicit（150×25，与 RangeSlider 统一）供计算；无
    // contentItem（前景在 handle 内、不占控件尺寸）——contentItem 项恒 0，
    // implicit 只由 background 项决定。
    implicitWidth: leftInset + implicitBackgroundWidth + rightInset
    implicitHeight: topInset + implicitBackgroundHeight + bottomInset

    SmartObject {
        id: pCtrl
        // 常态收缩量：轨道与手柄从全尺寸收缩的量（hover/按下/锁存展开时
        // 手柄占满可用高；轨道恒为常态——静态，不参与交互反馈）。
        readonly property real shrinkSize: Qore.bound(3, root.height * 0.25, 25)
        // 收缩偏移量的一半——轨道垂直居中（收缩后上下各留 shrinkSize/2）。
        readonly property real halfShrinkSpace: shrinkSize / 2
    }

    // —— 轨道（六边形渐变）：Crystal 六边形模型——与手柄同模型、斜边斜率
    // 一致天然对齐（OctagonShape 双层模型——QoolBoxGadget 半平面交集下
    // 切角极限形态合法，Crystal 即 cut = shortEdge/2 特化）。background 显式
    // implicit（150×25）供控件 implicit 计算；尺寸经 Control 标准自动布局
    // （background 自动 fill 控件 − insets，宿主替换新实例同样受控——插拔
    // 安全）。轨道恒为常态高度（不随展开变）+ 垂直居中（y = shrinkSize/2）
    // ——三心对齐（水晶中心 = 轨道中心 = 控件中心，水晶常态与轨道同高贴斜
    // 边；展开时水晶顶出轨道但不出控件）
    background: Item {
        implicitHeight: 25
        implicitWidth: 150

        Crystal {
            id: track
            objectName: "track" // 供 QML 测试读取（组件内部对象零暴露原则的测试例外——轨道静态性是公开视觉契约）
            // 轨道宽 = 容器宽（尖点贴边——Slider 不外溢）；常态收缩 + 居中
            width: parent.width
            height: parent.height - pCtrl.shrinkSize
            y: pCtrl.halfShrinkSpace
            // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
            color: root.color
            borderColor: root.borderColor
            fillGradient: LinearGradient {
                // 渐变内联默认（Slider 不暴露 fillGradient 通道，换色走 color
                // 属性）：左端 = backgroundColor 75% 透明（轨道同 RangeSlider
                // ——背景色半透明）、右端 = color；锚定切角内侧——与 Crystal
                // 中心行程对齐（colorAt(visualPosition) 精确采样）；坐标用
                // track 自身尺寸（收缩后切角 = track.height/2）
                x1: track.height / 2
                y1: track.height / 2
                x2: track.width - track.height / 2
                y2: track.height / 2
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.backgroundColor, 0.75)
                }
                GradientStop {
                    position: 1
                    color: root.color
                }
            }
        }
    } //background

    // —— 手柄（Crystal 菱形）：尺寸跟随可用区高度（六边形对齐语义）；展开
    // 反馈 = hover/按下/值变化锁存三态展开——
    handle: Item {
        id: handleRoot
        height: root.availableHeight
        width: height
        // handle delegate 须自写定位（模板不注入）——官方公式；Crystal 左上
        // 锚定，菱形中心 = 值位置（中心行程 [h/2, availW-h/2]，顶点贴端）
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

        // 值变化锁存（TimerLatch）：拖动/键盘/程序化改值后手柄保持展开
        // interval（500ms）——值变化即触发（滑动窗口内持续保持），与 hover/
        // 按下共同驱动 resized（hovered || pressed || latch.active），避免
        // 改值瞬间收缩再展开的闪动。锁存内化于 handle——不暴露接口（宿主的
        // "刚移动"感知经手柄展开反馈呈现，无需读锁存状态）。
        TimerLatch {
            id: latch
            interval: 500
            Connections {
                target: root
                function onValueChanged() {
                    latch.trigger();
                }
            }
        }

        ColorMapper {
            id: colorMapper
            // 采样渐变不透明化：轨道渐变左端 0.75 透明背景色，手柄为实体
            // 不透明（同 RangeSlider——轨道半透明、前景不透明）
            ColorMapperStop {
                position: 0
                color: root.backgroundColor
            }
            ColorMapperStop {
                position: 1
                color: root.color
            }
        }

        // 手柄尺寸动画（Qool 非可视组件）：from = 可用高 − 收缩量（常态）、
        // to = 可用高全尺寸（hover/按下/值变化锁存展开）；resized =
        // hoverer.hovered || root.pressed || latch.active 驱动 from↔to 切换
        // （动画门控 animationEnabled——关闭时跳变）；enabled 门控 resized
        // 响应——禁用时手柄冻结（与 hover/光标同受 root.enabled 控制）。
        ItemAnimatedResizer {
            id: cResizer
            enabled: root.enabled
            animationEnabled: root.animationEnabled

            fromWidth: handleRoot.height - pCtrl.shrinkSize
            fromHeight: handleRoot.height - pCtrl.shrinkSize

            toWidth: handleRoot.height
            toHeight: handleRoot.height

            resized: hoverer.hovered || root.pressed || latch.active
        }

        // 手柄 Crystal（菱形——宽高相等）：尺寸随 cResizer（hover/按下/锁存
        // 展开、常态收缩）、居中于 handle。色 = 轨道渐变在值位置的采样色
        // （colorAt 精确——拖动实时变化）。
        Crystal {
            id: crystal
            // 动画期间 CurveRenderer（原生 AA——展开缩放时小菱形边缘平滑且不重
            // 三角化），静止回退默认 GeometryRenderer（零额外成本）。仅手柄需要
            // （小尺寸亚像素毛躁；轨道为宽条像素充足——全局 CurveRenderer 帧数
            // 降、layer MSAA 缩放性能降，按需切换折中）
            preferredRendererType: root.animationEnabled ? Shape.CurveRenderer : Shape.UnknownRenderer
            width: cResizer.width
            height: cResizer.height
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

            // 常态色 = 轨道渐变在值位置的采样色（colorAt 精确）；反馈仅展开
            color: colorMapper.colorAt(root.visualPosition)
        }
    } //handle
}
