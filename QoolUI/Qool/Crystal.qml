// 水晶组件：八点模型（标准 ShapeControl + CrystalGadget 预制点）。
//
// 与 v3 ColorCrystal（独立 4 点菱形 Shape）的关系与差异（刻意）：
//   - 八点模型（四角排除域的顶点）：cutSize = shortEdge/2（gadget 中间量——
//     一次绑定，按需触发）——同一模型覆盖宽六边形（w > h）/ 菱形（w = h——
//     旋转 45° 正方形，四点重合收缩）/ 瘦六边形（w < h——上下尖 + 左右直边）。
//     统一 8 点路径对三种形态都合法（重合/共线点是合法冗余），无需路径分支。
//   - **单层外轮廓模型**（无内缩边框环）：细描边（strokeWidth 1 固定）——
//     不存在 QoolBoxShapeControl 双层模型在切角极限（顶点重合）时内边缘
//     反向三角形的问题（该 bug 为 OctagonShape 整体机制已知问题，八边形
//     正常、不计划修复——退化形态勿用 OctagonShape）。
//   - 轨道与手柄同模型：Slider 的轨道（宽条六边形）与手柄（方形菱形）斜边
//     斜率一致——天然对齐（水晶顶点贴轨道斜边）。
//   - 菱形左上角锚定（中心 = (width/2, height/2)），定位方式与普通 Item 一致
//     （v3 ColorCrystal 的"中心在原点"仅被 Color 模块 ColorCursor 依赖，
//     Color 侧保留原私有件；本件为 Qool 公开件）。
//   - **精确命中掩码**（CrystalGadget::contains——外接矩形内四角切角域
//     排除，斜边与八点顶点命中）：独立使用场景命中域与可见形状一致。
//
// 结构决策（root 为 Item + 内部 Shape anchors.fill）：与 HalfCrystal 同构。
// Qt 6.6+ 的 Shape 引擎在路径变化时强制 setImplicitSize(路径边界)——
// 路径点随组件尺寸变化的组件若以 Shape 为根，implicit 尺寸即路径边界，
// 布局会按 implicit 回写组件尺寸 → 尺寸 → 路径 → implicit → 尺寸正反馈环
// （HalfCrystal 曾实测：非方形实例持续 Binding loop + 尺寸不断放大）。
// 包一层 Item 根：引擎 implicit 更新只作用于内部 Shape（anchors.fill 锚定
// 尺寸，implicit 不参与布局），root 的 implicit 固定 20×20——环断开。

import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype Crystal
    \inqmlmodule Qool
    \brief 水晶六边形色块（八点模型）：\c width > \c height 为六边形、
    \c width = \c height 为菱形（旋转 45° 的正方形）、\c width < \c height
    为瘦六边形（上下尖 + 左右直边）。左上角锚定。

    八点几何由标准 \l {Qool::ShapeControl}{ShapeControl} 挂载
    \l {Qool::CrystalGadget}{CrystalGadget} 预制点提供（gadget 中间量
    \c cutSize = shortEdge/2——一次绑定按需触发）。单层外轮廓模型，
    细描边固定 1px（组件语义：不设宽边框，故无需内缩算法）。

    \section2 用法
    \list
    \li 手柄（方形）：默认 \c implicitWidth/\c implicitHeight 20×20（宽 = 高
        ——菱形）；轨道（宽条）：覆盖 \c width/\c height（宽六边形）。Slider
        的轨道与手柄均用本件，斜边斜率一致天然对齐。
    \li \c color 为纯色填充；\c fillGradient / \c fillItem 为填充通道
        （\l {Qool::OctagonShape}{OctagonShape} 同款语义——fillItem 优先）。
    \li 渐变锚点（左上/右上斜边内侧交点）不另暴露——宿主按
        \c{(width/2, height/2)} 与 \c{(width - width/2, height/2)} 自算
        （Slider 即此）。
    \endlist

    \section2 易误解点
    \list
    \li 菱形中心在 \c (width/2, height/2)（左上角锚定）——本件 x/y 即外接框
        左上角，定位方式与普通 Item 一致。
    \li 八点路径统一（TL→TC→TR→RT→RB→BC→LB→LT），三种形态下重合/共线点
        是合法冗余——宿主无需按形态切换路径。
    \li \c strokeWidth 固定 1：单层模型不支持宽边框（宽边框需内缩算法，
        与"切角极限合法"的设计矛盾）。
    \li **精确命中掩码**（CrystalGadget::contains——外接矩形内四角切角域
        排除，斜边与八点顶点命中）。\b hover 需显式挂载：Qt 的 hover 分发
        只检查 item 自身的 \c contains（不检查祖先掩码）——宿主 MouseArea
        挂 \c{containmentMask: 组件id.containmentMask} 才获得精确 hover
        （与 HalfCrystal 同机制，用法见 HalfCrystal「命中掩码」章节）。
    \li implicit 20×20 由 Item 根固定（内部 Shape 的 implicit 不参与布局）
        ——与 HalfCrystal 同构，Shape 根组件被隐式布局容器放大/循环的
        陷阱已断开。
    \endlist
*/
Item {
    id: root

    /*! \qmlproperty color 填充色，默认 Style.accent（独立使用默认自洽）。 */
    property color color: root.Style.accent
    /*! \qmlproperty color 描边色，默认按填充色自动对比（ThemeHQ.recommendForeground）。 */
    property color strokeColor: ThemeHQ.recommendForeground(root.color)
    /*! \qmlproperty Gradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变）。 */
    property Gradient fillGradient: null
    /*! \qmlproperty Item 纹理填充通道（OctagonShape 同款语义，优先于渐变/纯色）。 */
    property Item fillItem: null
    /*! \qmlproperty real 四角切角（等腰直角三角形直角边 = shortEdge/2）——八点与几何的统一基准。 */
    readonly property real cutSize: gadget.cutSize

    implicitWidth: 20
    implicitHeight: 20

    // 精确命中掩码（CrystalGadget::contains——本地坐标判定，见 crystal.cpp）
    containmentMask: gadget

    // 内部 Shape（anchors.fill——尺寸恒等于 root；引擎 implicit 更新只作用
    // 于此，不参与布局）。标准 ShapeControl 基座（target 自动 = 内部
    // Shape）+ CrystalGadget 预制点（gadget 作为 control 子对象自动关联；
    // 几何全部链 control——无需显式 target；单层简单组件不暴露 control
    // 属性——与 QoolBox 系列的多层公用场景区分）
    Shape {
        anchors.fill: parent

        ShapeControl {
            CrystalGadget {
                id: gadget
            }
        }

        ShapePath {
            id: mainPath
            startX: gadget.TLx
            startY: gadget.TLy
            PathLine {
                x: gadget.TCx
                y: gadget.TCy
            }
            PathLine {
                x: gadget.TRx
                y: gadget.TRy
            }
            PathLine {
                x: gadget.RTx
                y: gadget.RTy
            }
            PathLine {
                x: gadget.RBx
                y: gadget.RBy
            }
            PathLine {
                x: gadget.BCx
                y: gadget.BCy
            }
            PathLine {
                x: gadget.LBx
                y: gadget.LBy
            }
            PathLine {
                x: gadget.LTx
                y: gadget.LTy
            }
            PathLine {
                x: gadget.TLx
                y: gadget.TLy
            }
            fillColor: root.color
            strokeColor: root.strokeColor
            strokeWidth: 1 // 细描边固定（单层模型——见文件头注释）
            fillGradient: root.fillGradient
            fillItem: root.fillItem
        } //mainPath
    } //Shape
}
