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
//   - 菱形左上角锚定（中心 = (size/2, size/2)），定位方式与普通 Item 一致
//     （v3 ColorCrystal 的"中心在原点"仅被 Color 模块 ColorCursor 依赖，
//     Color 侧保留原私有件；本件为 Components 公开件）。
//   - **无精确命中掩码**（基类 contains = 外接矩形）：Slider 场景手柄不接收
//     鼠标（交互在控件层），掩码无意义；独立使用场景命中域为外接矩形
//     （菱形外四角也命中）——如需精确菱形命中，宿主自行提供 containmentMask。

import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype Crystal
    \inqmlmodule Qool.Controls.Components
    \brief 水晶六边形色块（八点模型）：\c width > \c height 为六边形、
    \c width = \c height 为菱形（旋转 45° 的正方形）、\c width < \c height
    为瘦六边形（上下尖 + 左右直边）。左上角锚定。

    八点几何由标准 \l {Qool::ShapeControl}{ShapeControl} 挂载
    \l {Qool::CrystalGadget}{CrystalGadget} 预制点提供（gadget 中间量
    \c cutSize = shortEdge/2——一次绑定按需触发）。单层外轮廓模型，
    细描边固定 1px（组件语义：不设宽边框，故无需内缩算法）。

    \section2 用法
    \list
    \li 手柄（方形）：设 \c size（宽高相等——菱形）；轨道（宽条）：覆盖
        \c width/\c height（宽六边形）。Slider 的轨道与手柄均用本件，
        斜边斜率一致天然对齐。
    \li \c color 为纯色填充；\c fillGradient / \c fillItem 为填充通道
        （\l {Qool::OctagonShape}{OctagonShape} 同款语义——fillItem 优先）。
    \li \c leftPoint / \c rightPoint 为渐变锚点（左上/右上斜边内侧交点），
        供渐变横贯"有效轨道段"（v3 ColorSliderBackground 语义）。
    \endlist

    \section2 易误解点
    \list
    \li 菱形中心在 \c (size/2, size/2)（左上角锚定）——本件 x/y 即外接框
        左上角，定位方式与普通 Item 一致。
    \li 八点路径统一（TL→TC→TR→RT→RB→BC→LB→LT），三种形态下重合/共线点
        是合法冗余——宿主无需按形态切换路径。
    \li \c strokeWidth 固定 1：单层模型不支持宽边框（宽边框需内缩算法，
        与"切角极限合法"的设计矛盾）。
    \li **命中域为外接矩形**（无精确菱形掩码——见文件头注释）。
    \endlist
*/
Shape {
    id: root

    /*! \qmlproperty real 外接框尺寸（宽 = 高 = size，菱形形态），默认 20。 */
    property real size: 20
    /*! \qmlproperty color 填充色，默认 Style.accent（独立使用默认自洽）。 */
    property color color: root.Style.accent
    /*! \qmlproperty color 描边色，默认按填充色自动对比（ThemeDB.recommendForeground）。 */
    property color strokeColor: ThemeDB.recommendForeground(root.color)
    /*! \qmlproperty Gradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变）。 */
    property Gradient fillGradient: null
    /*! \qmlproperty Item 纹理填充通道（OctagonShape 同款语义，优先于渐变/纯色）。 */
    property Item fillItem: null
    /*! \qmlproperty real 四角切角（等腰直角三角形直角边 = shortEdge/2）——八点与几何的统一基准。 */
    readonly property real cutSize: gadget.cutSize
    /*! \qmlproperty point 左上斜边内侧交点（渐变锚点，v3 leftPoint 语义）。 */
    readonly property point leftPoint: Qt.point(gadget.TLx, gadget.LTy)
    /*! \qmlproperty point 右上斜边内侧交点（渐变锚点，v3 rightPoint 语义）。 */
    readonly property point rightPoint: Qt.point(gadget.TRx, gadget.RTy)

    width: size
    height: size

    // 标准 ShapeControl 基座（target 自动 = 本组件）+ CrystalGadget 预制点
    // （gadget 作为 control 子对象自动关联；几何全部链 control——无需显式 target）
    readonly property ShapeControl control: ShapeControl {
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
}
