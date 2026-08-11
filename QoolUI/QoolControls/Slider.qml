// Qool.Controls.Slider：v3 Color 水平滑块（ColorSlider 视觉族）的通用化实现。
//
// 设计来源（用户裁决 2026-08-10——放弃首版 Box 设计）：
//   - 轨道与手柄统一为**水晶六边形模型**（Crystal 组件 + CrystalShapeControl
//     ——Qool ShapeControl 体系）：上下 45° 斜切、左右尖点；轨道为宽条六边形、
//     手柄为方形（w = h 自然闭合菱形——旋转 45° 正方形）。同模型斜边斜率
//     一致——天然对齐（水晶顶点贴轨道斜边）。
//   - 单层外轮廓模型（无内缩边框环）：细描边/无描边——不存在 OctagonShape
//     双层模型在切角极限（顶点重合）时内边缘反向三角形的问题（OctagonShape
//     该机制为已知 bug，八边形正常、不计划修复——六边形/菱形勿用）。
//   - 轨道默认填充 text→color 水平渐变（锚定切角内侧——Crystal 渐变锚点
//     语义，用轨道局部尺寸计算）；渐变内联不可替换（v4 收缩裁定：换色走
//     color 属性，不再提供 fillGradient/fillItem 透传通道）。
//   - 手柄展开反馈照 v3 ColorCursor 核心：悬停/按下/刚移动三态展开——展开
//     态占满 handle 区域（= 控件高度，不超出边界），常态 = preferredHeight
//     （root.height - bound(3, 高度×25%, 25)——轨道同步收缩同高，顶点贴斜边
//     关系保持；x 上限 25 封顶收缩量、下限 3 防常态过小），动画经
//     animationEnabled 链式门控（parent?.animationEnabled ?? Style.animationEnabled）。
//     v3 的 pCtrl.initialized 延迟一帧取消——初始就绪态无属性变化，无需防初始动画。
//   - Crystal 常态色 = 轨道渐变在当前值位置的采样色（ColorMapper.colorAt）——
//     数学上近似精确：渐变锚定 [pH/2, availW-pH/2]（pH = preferredHeight，
//     切角内侧）与 Crystal 中心行程 [h/2 + v*(availW-h)]（h = root.height）
//     在轨道收缩（pH < h）时端点有 ≤ x/2 的微小偏移（v=0/1 采不到纯端色，
//     中段比例仍近似等于 visualPosition）。v3 的 pressed/锁存 lighter 提亮
//     已裁定取消（保留展开反馈为唯一手柄反馈）。
//   - 程序化变更锁存（TimerLatch + NumberNotifier）：value 被写入（无论谁写
//     的）→ movementLatch 锁存 500ms → 手柄展开（v3 ChannelBar movementTimer
//     语义）。双触发源：valueChanged 即时触发 + velocityChanged（采样级——
//     晚于 valueChanged 至多一个采样间隔 200ms）在持续变化期间周期性重置，
//     窗口不落。
//   - 交互为模板默认（点击跳转 + 拖动连续 + 键盘），映射公式（中心语义）与
//     Crystal 定位自洽；轨道常态高 = preferredHeight（跟随控件高度收缩）——
//     手柄常态与轨道同高（v3 语义：六边形左右斜边与水晶顶点对齐，宿主改高
//     后等比例缩放）、展开占满控件全高，尺寸公式模板不自带——反向排版：
//     root 直接给默认 implicit（80 × 25），background 基于 root 布局。
//   - 值显示（首版双色文本）放弃；无进度填充段（v3 原样）。
//
// 公开属性：
//   - color：轨道渐变右端色（默认 Style.accent——左端固定 Style.text）——宿主
//     换色即换整条轨道渐变 + Crystal 采样。
//   - animationEnabled：动画门控（父链继承，回退 Style.animationEnabled）。
//   - valueVelocity / justMoved：对外状态——值变化速率（值/秒）与"刚移动"
//     锁存窗口（500ms）。
//   - preferredHeight：水晶/轨道常态高度（收缩态）——展开时水晶占满控件全高。
//
// 注意（易误解）：
//   - handle delegate 必须自写 x/y（T.Slider 模板不注入定位——宿主替换 handle
//     时同样要写，官方惯例）。
//   - 手柄展开态占满控件高度（不超出边界）——clip 与否不影响反馈（v3"菱形
//     顶出轨道"刻意效果已取消）。
//   - 手柄 MouseArea 仅做 hover/光标反馈（acceptedButtons: Qt.NoButton——
//     不拦截模板拖动；Crystal 已补精确掩码，手柄仍不设 containmentMask——
//     NoButton 仅光标反馈、hover 域宽松为刻意设计）。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool

/*!
    \qmltype Slider
    \inqmlmodule Qool.Controls
    \brief 水平滑块：六边形渐变轨道 + 水晶菱形手柄（v3 Color 滑块视觉族）。

    交互为模板默认（点击跳转、拖动连续、方向键步进——官方行为，接口兼容
    QtQuick.Templates.Slider）。轨道与手柄统一为
    \l {Qool::Crystal}{Crystal} 六边形模型（轨道为宽条
    六边形、手柄为方形菱形——同模型斜边斜率一致天然对齐），轨道默认填充
    \c text → \c color 水平渐变（左端固定 Style.text，右端 = \l color，默认
    Style.accent）；手柄常态色 = 轨道渐变在当前值位置的采样色
    （ColorMapper.colorAt(visualPosition)——随位置实时变化）。

    \section2 主题相关
    \list
    \li \l color 同时是渐变右端色与手柄采样来源——宿主换色即换整条轨道视觉。
    \li 轨道渐变内联默认（text→color，锚定切角内侧）——整体替换不再提供
        （v4 收缩）；换色走 \l color，改尺寸走 \c width/\c height 覆盖。
    \endlist

    \section2 交互反馈
    \list
    \li 悬停/按下/刚移动（值变化后 500ms 锁存窗口）：手柄展开到控件全高
        （常态 = \l preferredHeight——收缩 \c{Qore.bound(3, 高度×0.25, 25)}，
        视觉差即放大反馈；轨道与手柄常态同高、中心对齐贴斜边），动画随
        \l animationEnabled 门控；悬停时光标变水平双向箭头（仅 enabled）。
    \li 程序化写入 value（如外部绑定）：手柄展开约 500ms（\l justMoved 锁存
        窗口）——"值被写入即反馈"语义（v3 ChannelBar movementTimer，无论谁
        写的）；持续变化期间窗口经 \l valueVelocity 采样级重置不落。
    \li 倒置范围（from > to）：刻度反向，渐变/采样自动跟随 visualPosition。
    \endlist

    \section2 状态属性
    \list
    \li \c animationEnabled：动画开关——父链继承（宿主可在父级统一关闭），
        回退 \l Style 的 \c animationEnabled。
    \li \c valueVelocity：值变化速率（值/秒，NumberNotifier 200ms 采样、
        有向、骤停归零）。
    \li \c justMoved："值刚被写入过"的声明式锁存窗口（500ms，滑动窗口）。
    \li \c preferredHeight：水晶手柄与轨道的常态高度（收缩态）——展开时
        水晶占满控件全高；宿主可用它参与外部布局计算。
    \endlist

    \note 手柄展开态占满控件高度（不超出边界）——\c clip 与否不影响反馈
    （v3"菱形顶出轨道"刻意效果已取消）。
*/
T.Slider {
    id: root
    /*! \qmlproperty color 轨道渐变右端色（左端固定 Style.text），默认 Style.accent。 */
    property color color: root.Style.accent
    /*! \qmlproperty real 值变化速率（值/秒，NumberNotifier 200ms 采样、有向、骤停归零）。 */
    readonly property real valueVelocity: notifier.velocity
    /*! \qmlproperty bool "值刚被写入过"的声明式锁存窗口（500ms，滑动窗口——持续变化持续保持）。 */
    property bool justMoved: movementLatch.active
    /*! \qmlproperty bool 动画门控——父链继承（宿主可在父级统一关闭），回退 Style.animationEnabled。 */
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled
    /*! \qmlproperty real 常态高度：水晶手柄与轨道的常态（收缩）高度——展开时水晶占满控件全高（root.height）。 */
    readonly property real preferredHeight: root.height - Qore.bound(3, root.height * 0.25, 25)

    // 尺寸：反向排版策略——模板不自带 implicit 公式，root 直接给默认尺寸
    // （80 × 25），background 基于 root 布局（自动 fill 控件——切角/渐变
    // 锚定绑定 track 自身尺寸，随 root 缩放）——不依赖 implicitBackground*
    // 的传递链（曾致高度恒 0；交互恢复实测于本策略）
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

    // —— 轨道（六边形）：Crystal 组件（六边形模型——与手柄同模型、斜边斜率
    // 一致天然对齐；单层外轮廓——无 OctagonShape 双层内缩在切角极限（顶点
    // 重合）时的反向三角形 bug，性能亦轻）。显式绑定控件尺寸（覆盖 Crystal
    // 的 implicit 默认——background 自动 fill 在 Crystal 有尺寸绑定时未生效，
    // 曾致轨道缩成 20×20 菱形在左上角）。轨道恒为常态高度（preferredHeight，
    // 不随展开变）+ 垂直居中——三心对齐（水晶中心 = 轨道中心 = 控件中心，
    // 水晶常态与轨道同高贴斜边；展开时水晶顶出轨道但不出控件）
    background: Crystal {
        id: track
        width: root.width
        height: root.preferredHeight
        y: (root.height - height) / 2
        // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
        color: root.color
        fillGradient: LinearGradient {
            // 渐变内联默认（Slider 不再暴露 fillGradient——v4 收缩裁定，换色走
            // color 属性）：锚定切角内侧（v3 渐变锚点语义）——与 Crystal 中心
            // 行程对齐（colorAt(visualPosition) 精确采样——见文件头注释的数学）；
            // 坐标用 track 局部尺寸（轨道收缩后切角 = track.height/2）
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

    // —— 手柄（Crystal 菱形）：尺寸跟随控件高度（六边形对齐语义——见文件头）；
    // 展开反馈照 v3 ColorCursor 核心——
    handle: Item {
        id: handleRoot
        height: root.height
        width: height
        // handle delegate 须自写定位（模板不注入）——官方公式；Crystal 左上锚定，
        // 菱形中心 = 值位置（v3 语义：中心行程 [h/2, availW-h/2]，顶点贴端）
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
            // （小尺寸亚像素毛躁；轨道为宽条像素充足——2026-08-10 裁定：全局
            // CurveRenderer 帧数降、layer MSAA 缩放性能降，按需切换折中）
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
            // 高度（preferredHeight——同收缩贴斜边；2026-08-10 裁定：原
            // "展开超出边界"刻意效果取消）
            readonly property bool encountered: {
                return hoverer.hovered || root.pressed || root.justMoved;
            }

            width: height
            height: encountered ? root.height : root.preferredHeight
            BasicNumberBehavior on height {
                enabled: root.animationEnabled
                duration: Style.transitionDuration
            }
            // 常态色 = 轨道渐变在值位置的采样色（colorAt 精确——见文件头）；
            // 反馈仅展开（v3 的 pressed/锁存 lighter 提亮已裁定取消）
            color: colorMapper.colorAt(root.visualPosition)
            // Behavior 须声明在本对象内（on 作用于声明者自己的属性）
        }
    } //handle
}
