// 三角版 Crystal 组件：四点模型（内部最大正方形四边中点）的 Shape 组件。
// direction（Qore.N/S/W/E）切换三角形指向，其余方向值显示完整菱形。
//
// 与 Crystal 同一视觉语言：45° 斜边、对轴、四通道填充（color/strokeColor/
// fillGradient/fillItem）、单层 1px 描边。无 cutSize（三角形无切角概念）。
//
// 几何链：ShapeControl（target 自动 = 内部 Shape）→ RectGadget gA（源头）→
// RectGadget gB（画布）。gA 跟踪内部 Shape 几何（= root 几何，anchors.fill），
// 提供 maxInnerSquareRect（shortEdge 居中）；gB 四元 QML 绑定为本地画布坐标
// （x/y 减 gA.x/gA.y 抵消父坐标偏移——组件任意位置/父变换下掩码与渲染同基准）。
//
// 渲染链：gB（数据源）→ pCtrl（四渲染参考值 northY/southY/westX/eastX）→
// Path 四点（(cx,northY)/(eastX,cy)/(cx,southY)/(westX,cy)）。direction 决定
// 对侧点移到中心（共线隐藏于底边中点）；中间态恒为菱形。Gadget 点不挂
// Behavior——动画只挂 pCtrl 会变的参数（N/S 仅 Y 动、W/E 仅 X 动）。
//
// 精确命中掩码（HalfCrystalGadget C++ contains——geometrySource = gB 画布 +
// direction）：shapeRect 粗判 + 内部正方形四角域排除（开集语义，斜边命中）。
//
// 结构决策（root 为 Item + 内部 Shape anchors.fill）：Qt 6.6+ 的 Shape 引擎
// 在路径变化时强制 setImplicitSize(路径边界)（qquickshape.cpp
// _q_shapePathChanged）——路径点随组件尺寸变化的组件若以 Shape 为根，
// implicit 尺寸即路径边界，布局（QQuickControl 的 contentItem setSize /
// ColumnLayout 的 preferred 尺寸）会按 implicit 回写组件尺寸 → 尺寸 → 路径 →
// implicit → 尺寸正反馈环（描边扩展使每轮边界 > 几何，方形 k=1 恒发散）。
// 包一层 Item 根：引擎 implicit 更新只作用于内部 Shape（anchors.fill 锚定
// 尺寸，implicit 不参与布局），root 的 implicit 固定 20×20——环断开。
// Crystal 同为 Shape 根组件，同机制隐患（无 QML 绑定层故不报循环警告，
// 宿主将其放入隐式布局容器时同样会被放大——待评估同构修复）。

import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype HalfCrystal
    \inqmlmodule Qool
    \brief 三角版 Crystal 色块（四点模型）：\c direction 切换指向
    （Qore.N/S/W/E 为直角等腰三角形，其余值为完整菱形）。

    四点模型取内部最大正方形四边中点（斜边 45°、对轴、画布居中）：
    Path 四点 = \c{(cx, northY)/(eastX, cy)/(cx, southY)/(westX, cy)}。
    \c direction 决定对侧点移到中心（共线隐藏于底边中点）；中间态恒为
    菱形。任意 \c width/\c height 尺寸安全（三角形基于内部最大正方形
    居中）。

    \section2 方向语义
    \list
    \li N/S/W/E：直角等腰三角形（对侧点移到中心，底边 = 其余三点）。
    \li 其余值（\c Unknown/对角 NW/NE/SW/SE）：完整菱形（四点全原位）。
    \endlist

    \section2 样式通道
    \list
    \li \c color（默认 Style.accent）纯色填充；\c strokeColor
        （ThemeHQ.recommendForeground 自动对比）描边色。
    \li \c fillGradient / \c fillItem 渐变/纹理通道（fillItem 优先）——
        Crystal 同款语义，无内置渐变逻辑。
    \li 单层外轮廓模型，细描边固定 1px；implicit 20×20。
    \endlist

    \section2 动画
    方向切换经四个 \l {Qool::BasicNumberBehavior}{BasicNumberBehavior}
    （duration = \c Style.movementDuration，\c Style.animationEnabled 门控）
    平滑过渡——仅动画会变的参数：N/S 仅纵轴两点动、W/E 仅横轴两点动，
    中间态恒为菱形。

    \section2 命中掩码
    \c containmentMask 为 \l {Qool::HalfCrystalGadget}{HalfCrystalGadget}
    （C++ contains）精确判定——shapeRect（方向决定半区/整正方形）粗判 +
    内部正方形四角域排除（直角边 = shortEdge/2、斜边
    \c{dx+dy < shortEdge/2}——开集语义，斜边与直角边端点命中）。
    掩码引用 gB 瞬时几何（不跟动画层）——命中域即当前形状语义；
    组件平移/父变换后仍准确（掩码坐标与渲染同基准——本地画布坐标）。
*/
Item {
    id: root

    /*! \qmlproperty color 填充色，默认 Style.accent（独立使用默认自洽）。 */
    property color color: root.Style.accent
    /*! \qmlproperty color 描边色，默认按填充色自动对比（ThemeHQ.recommendForeground）。 */
    property color strokeColor: ThemeHQ.recommendForeground(root.color)
    /*! \qmlproperty Gradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变）。 */
    property Gradient fillGradient: null
    /*! \qmlproperty Item 纹理填充通道（Crystal 同款语义，优先于渐变/纯色）。 */
    property Item fillItem: null
    /*! \qmlproperty int 方向（Qore.Directions）——N/S/W/E 为三角形，其余值为完整菱形，默认 Qore.N。 */
    property int direction: Qore.N

    implicitWidth: 20
    implicitHeight: 20

    // 精确命中掩码：HalfCrystalGadget（C++ contains(QPointF)——containmentMask
    // 要求掩码对象 metaObject 上有该签名方法；QtObject 包装 QML function 在
    // Qt 6.11 实测不满足（签名不匹配，掩码被忽略）——故不走 QML function 路径
    containmentMask: maskGadget

    // —— 渲染与几何：内部 Shape（anchors.fill——尺寸恒等于 root）——
    // gA（源头，跟踪内部 Shape 几何 = root 几何）→ gB（画布，内部最大正方形）
    Shape {
        anchors.fill: parent

        ShapeControl {
            RectGadget {
                id: gA
            }
        }

        ShapeControl {
            RectGadget {
                id: gB
                // 四元 QML 绑定为本地画布坐标（相减抵消 gA 父坐标偏移——组件
                // 任意位置下掩码与渲染同基准；QML 绑定声明走 bindable
                // setBinding，不经过 set_rect——构造 target 绑定被 QML 绑定替换）
                x: gA.maxInnerSquareRect.x - gA.x
                y: gA.maxInnerSquareRect.y - gA.y
                width: gA.maxInnerSquareRect.width
                height: gA.maxInnerSquareRect.height
            }
            HalfCrystalGadget {
                id: maskGadget
                // 掩码几何源 = gB（瞬时几何——绑定驱动，方向切换动画期间
                // 命中域即当前形状语义）
                geometrySource: gB
                direction: root.direction
            }
        }

        // —— 渲染层：四点路径（Gadget 点不挂 Behavior——动画在 pCtrl 层）——
        ShapePath {
            id: mainPath
            startX: pCtrl.cx
            startY: pCtrl.northY
            PathLine {
                x: pCtrl.eastX
                y: pCtrl.cy
            }
            PathLine {
                x: pCtrl.cx
                y: pCtrl.southY
            }
            PathLine {
                x: pCtrl.westX
                y: pCtrl.cy
            }
            PathLine {
                x: pCtrl.cx
                y: pCtrl.northY
            }
            fillColor: root.color
            strokeColor: root.strokeColor
            strokeWidth: 1 // 细描边固定（单层模型——与 Crystal 同款语义）
            fillGradient: root.fillGradient
            fillItem: root.fillItem
        } //mainPath
    } //Shape

    // —— pCtrl：四个渲染参考值（direction 决定各取原位/中心；对侧点移到
    // 中心时共线隐藏于底边中点）。Behavior 只挂会变的参数——
    // N/S 仅 northY/southY 动（W/E 点仅 X 动）——
    QtObject {
        id: pCtrl

        readonly property real cx: gB.centerX
        readonly property real cy: gB.centerY
        readonly property real halfS: gB.shortEdge / 2
        readonly property bool isN: root.direction === Qore.N
        readonly property bool isS: root.direction === Qore.S
        readonly property bool isW: root.direction === Qore.W
        readonly property bool isE: root.direction === Qore.E

        // 非 readonly（实测：Qt 6.11.1 中 Behavior 挂在 readonly 属性上会使
        // 组件加载失败——"Did not load any objects"；pCtrl 为内部 QtObject，
        // 无外部契约约束，去 readonly 无副作用）
        property real northY: isS ? cy : cy - halfS
        property real southY: isN ? cy : cy + halfS
        property real westX: isE ? cx : cx - halfS
        property real eastX: isW ? cx : cx + halfS

        // 动画只挂会变的参数（N/S 仅 Y 动、W/E 仅 X 动——4 个 Behavior 而非
        // 8 个）；中间态恒为菱形（两点相向滑动）。enabled/duration 显式绑
        // root（pCtrl 为 QtObject 无 Style 附加属性——`Style.xxx` 在此作用域
        // 不可解析）
        BasicNumberBehavior on northY {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
        BasicNumberBehavior on southY {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
        BasicNumberBehavior on westX {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
        BasicNumberBehavior on eastX {
            enabled: root.Style.animationEnabled
            duration: root.Style.movementDuration
        }
    } //pCtrl
}
