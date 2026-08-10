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
//   - 轨道默认填充 text→color 水平渐变（锚定切角内侧——Crystal leftPoint/
//     rightPoint 语义），fillGradient/fillItem 双通道透传（宿主可替换）。
//   - 手柄展开反馈照 v3 ColorCursor 核心：悬停/按下/刚移动三态展开 hoveredSize
//     （+limit(size*0.25,15,45)），动画经 pCtrl.initialized 延迟一帧 +
//     animationEnabled 门控（v3 语义）。
//   - Crystal 常态色 = 轨道渐变在当前值位置的采样色（ColorMapper.colorAt）——
//     数学上 colorAt(visualPosition) 即精确采样：渐变锚定 [size/2, availW-size/2]
//     （切角内侧）= Crystal 中心行程 [size/2 + v*(availW-size)]，比例恒等于
//     visualPosition；pressed/锁存时在采样色上 lighter 1.4。
//   - 程序化变更锁存（TimerLatch + NumberNotifier 保留）：value 被写入（无论
//     谁写的）→ latch 激活 1s → Crystal 提亮（v3 ChannelBar movementTimer 语义）。
//   - 交互为模板默认（点击跳转 + 拖动连续 + 键盘），映射公式（中心语义）与
//     Crystal 定位自洽；轨道高 = 控件高（默认 crystalSize 20）——手柄菱形尺寸
//     跟随控件高度（v3 语义：轨道高 = 光标高，六边形左右斜边与水晶顶点对齐，
//     宿主改高后手柄等比例放大），尺寸公式模板不自带——反向排版：root 直接给
//     默认 implicit（80 × crystalSize），background 基于 root 布局。
//   - 值显示（首版双色文本）放弃；无进度填充段（v3 原样）。
//
// 公开属性（新增面）：
//   - color：轨道渐变右端色（默认 Style.accent——左端固定 Style.text）——宿主
//     换色即换整条轨道渐变 + Crystal 采样。
//   - crystalSize：默认控件高度（默认 20，implicitHeight = crystalSize）——
//     手柄尺寸跟随控件实际高度（非固定 crystalSize）。
//   - fillItem / fillGradient：轨道填充双通道透传（fillGradient 默认渐变、
//     fillItem 默认 null——宿主替换任一侧）。
//
// 注意（易误解）：
//   - handle delegate 必须自写 x/y（T.Slider 模板不注入定位——宿主替换 handle
//     时同样要写，官方惯例）。
//   - 宿主替换 fillGradient（自定义锚定）后 colorAt 采样按默认几何近似（渐变段
//     与 Crystal 行程不再严格对齐）——精确对齐仅对默认渐变成立。
//   - 手柄放大（展开态/超高轨道）超出控件边界是刻意效果（v3 语义——菱形顶出
//     轨道）——勿对 Slider 或其容器 clip（切掉即破坏反馈语言）。

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates as T
import Qool
import Qool.Controls.Components

/*!
    \qmltype Slider
    \inqmlmodule Qool.Controls
    \brief 水平滑块：六边形渐变轨道 + 水晶菱形手柄（v3 Color 滑块视觉族）。

    交互为模板默认（点击跳转、拖动连续、方向键步进——官方行为，接口兼容
    QtQuick.Templates.Slider）。轨道与手柄统一为
    \l {Qool.Controls.Components::Crystal}{Crystal} 六边形模型（轨道为宽条
    六边形、手柄为方形菱形——同模型斜边斜率一致天然对齐），轨道默认填充
    \c text → \c color 水平渐变（左端固定 Style.text，右端 = \l color，默认
    Style.accent）；手柄常态色 = 轨道渐变在当前值位置的采样色，按下/程序化
    变更期间提亮（lighter 1.4）。

    \section2 主题相关
    \list
    \li \l color 同时是渐变右端色与手柄采样来源——宿主换色即换整条轨道视觉。
    \li 轨道 \l fillGradient / \l fillItem 双通道透传：默认渐变可整体替换
        （LinearGradient 需锚定自己的坐标）；fillItem 为纹理通道（优先于渐变）。
    \li \c crystalSize 是默认控件高度（implicitHeight）；手柄菱形尺寸始终跟随
        控件实际高度（宿主改高后手柄等比例放大，六边形左右斜边与水晶顶点对齐）。
    \endlist

    \section2 交互反馈
    \list
    \li 悬停/按下/刚移动（值变化 1s 内）：手柄展开到 \c hoveredSize（v3
        ColorCursor 三态展开，动画随 Style.animationEnabled 门控）。
    \li 程序化写入 value（如外部绑定）：手柄提亮约 1s（TimerLatch 锁存窗口）
        ——"值被写入即亮"语义（v3 ChannelBar movementTimer，无论谁写的）。
    \li 倒置范围（from > to）：刻度反向，渐变/采样自动跟随 visualPosition。
    \endlist

    \note 手柄放大（展开态或宿主调高轨道）时超出控件边界是**刻意效果**（v3
    语义——菱形顶出轨道的视觉反馈）——宿主**不应**对本控件或其容器启用
    \c clip（会切掉展开效果）；控件自身不裁剪子项。
*/
T.Slider {
    id: root

    /*! \qmlproperty color 轨道渐变右端色（左端固定 Style.text），默认 Style.accent。 */
    property color color: root.Style.accent
    /*! \qmlproperty real 控件默认高度（implicitHeight = crystalSize，默认 20）——
        手柄菱形尺寸始终跟随控件高度（v3 语义：轨道高 = 水晶高，六边形左右斜边
        与水晶顶点对齐）——宿主改高后手柄自动等比例放大。 */
    property real crystalSize: 20
    /*! \qmlproperty Item 轨道纹理填充物（Crystal fillItem 透传，优先于渐变）。 */
    property Item fillItem: null
    /*! \qmlproperty Gradient 轨道渐变填充（默认 text→color 水平渐变，可整体替换）。 */
    property Gradient fillGradient: LinearGradient {
        // 默认渐变（属性默认值内联对象——合法语法；宿主替换 fillGradient 即覆盖）：
        // 锚定切角内侧（v3 leftPoint/rightPoint 语义）——与 Crystal 中心行程对齐
        // （colorAt(visualPosition) 精确采样——见文件头注释的数学）
        x1: root.height / 2
        y1: root.height / 2
        x2: root.width - root.height / 2
        y2: root.height / 2
        GradientStop {
            position: 0
            color: root.Style.text
        }
        GradientStop {
            position: 1
            color: root.color
        }
    }

    // 尺寸：反向排版策略——模板不自带 implicit 公式，root 直接给默认尺寸
    // （80 × crystalSize），background 基于 root 布局（自动 fill 控件——切角/
    // 渐变锚定绑定 track 自身尺寸，随 root 缩放）——不依赖 implicitBackground*
    // 的传递链（曾致高度恒 0；交互恢复实测于本策略）
    implicitWidth: 80
    implicitHeight: root.crystalSize

    // —— 渐变采样器（Crystal 常态色来源——QoolCommon/ColorMapper 设施）——
    ColorMapper {
        id: trackMapper
        ColorMapperStop { position: 0; color: root.Style.text }
        ColorMapperStop { position: 1; color: root.color }
    }

    // —— 逻辑件：程序化变更锁存（NumberNotifier 采样 → TimerLatch 激活）——
    NumberNotifier {
        id: notifier
        target: root
        property: "value"
        interval: 200
    }
    Connections {
        target: notifier
        function onValueUpdated() {
            latch.activate()
        }
    }
    TimerLatch {
        id: latch
        interval: 1000
    }

    // —— 轨道（六边形）：Crystal 组件（六边形模型——与手柄同模型、斜边斜率
    // 一致天然对齐；单层外轮廓——无 OctagonShape 双层内缩在切角极限（顶点
    // 重合）时的反向三角形 bug，性能亦轻）。显式绑定控件尺寸（覆盖 Crystal
    // 的 size 绑定——background 自动 fill 在 Crystal 有尺寸绑定时未生效，
    // 曾致轨道缩成 20×20 菱形在左上角；渐变锚定用 root 尺寸——与 track 的
    // leftPoint/rightPoint 等价，因 track.height = root.height）
    background: Crystal {
        id: track
        width: root.width
        height: root.height
        // 兜底纯色（渐变通道失效时轨道仍可见——渐进降级；渐变生效时覆盖）
        color: root.color
        fillGradient: root.fillGradient
        fillItem: root.fillItem
    } //background

    // —— 手柄（Crystal 菱形）：尺寸跟随控件高度（六边形对齐语义——见文件头）；
    // 展开反馈照 v3 ColorCursor 核心——
    handle: Item {
        id: handleRoot
        width: root.height
        height: root.height
        // handle delegate 须自写定位（模板不注入）——官方公式；Crystal 左上锚定，
        // 菱形中心 = 值位置（v3 语义：中心行程 [size/2, availW-size/2]，顶点贴端）
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2

        Crystal {
            id: crystal
            anchors.centerIn: parent
            size: pCtrl.hovering ? pCtrl.hoveredSize : root.height
            // 常态色 = 轨道渐变在值位置的采样色（colorAt 精确——见文件头）；
            // pressed/锁存 → lighter 提亮
            color: root.pressed || latch.active
                   ? Qt.lighter(trackMapper.colorAt(root.visualPosition), 1.4)
                   : trackMapper.colorAt(root.visualPosition)
            // Behavior 须声明在本对象内（on 作用于声明者自己的属性）
            BasicNumberBehavior on size {
                enabled: pCtrl.animationEnabled
            }
            BasicColorBehavior on color {
                enabled: pCtrl.animationEnabled
            }
        }

        // 展开逻辑（v3 ColorCursor 核心：悬停/交互/刚移动三态 → hoveredSize；
        // initialized 延迟一帧——创建时不对默认值动画）
        QtObject {
            id: pCtrl
            property bool initialized: false
            readonly property bool animationEnabled: initialized
                                                     && (!root.pressed)
                                                     && root.Style.animationEnabled
            readonly property bool hovering: hoverer.hovered || root.pressed
                                             || movementTimer.justMoved
            readonly property real hoveredSize: {
                let delta = root.height * 0.25
                delta = Math.max(15, Math.min(45, delta)) // v3 limitNumber(delta,15,45)
                return root.height + delta
            }
        }

        HoverHandler {
            id: hoverer
            enabled: root.enabled // disabled 时无悬停反馈（常态外观）
        }

        Timer {
            id: movementTimer
            property bool justMoved: false
            interval: 1000
            onTriggered: justMoved = false
            function when_moved() {
                justMoved = true
                restart()
            }
        }
        Connections {
            target: handleRoot
            function onXChanged() {
                movementTimer.when_moved()
            }
            function onYChanged() {
                movementTimer.when_moved()
            }
        }

        Component.onCompleted: pCtrl.initialized = true
    } //handle
}
