// 三角版 Crystal 组件：四点模型（内部最大正方形四边中点）的 Shape 组件。
// direction（Qore.N/S/W/E）切换三角形指向，其余方向值显示完整菱形
// （水晶型——默认形态）。
//
// 与 Crystal 同一视觉语言：45° 斜边、对轴、四通道填充（color/borderColor/
// fillGradient/fillItem）。无 cutSize（三角形无切角概念）。
//
// 结构（用户裁决 2026-08-16）：
// - 根 = Shape（Shape 即 Item——定位/锚定/父变换能力不损失）；显式
//   width/height 20 为默认逻辑尺寸（implicit 声明在 Shape 根上被引擎
//   无条件覆盖——Crystal 同机制）。
// - 几何链：pCtrl = ShapeControl 实例（target 自动 = 根 Shape）→
//   RectGadget gA（源头，跟踪根尺寸）→ RectGadget gB（内接画布 =
//   maxInnerSquareRect——RectGadget x/y 固定 0，该矩形即根内部坐标，
//   一步 rect 直绑；坐标系语义见 qool_shapegadget_rect.cpp QDoc）。
// - 中间量（readonly 标量，内描边几何的核心——确定后各形态仅剩轴与
//   符号选择）——内缩量直接用 borderWidth 线性推导，无收缩极限钳制
//   （用户裁决 2026-08-16——不设 effInset）：
//   - rInset（直角内缩）= √2·b——90° 角沿角平分线内缩（斜边法线
//     位移 = √2b·cos45° = b，环宽均匀）；
//   - sInsetX / sInsetY（尖角内缩）= (1+√2)·b / b——45° 角（三角
//     底角）内缩分量：底边法线位移 = sInsetY = b、斜边法线位移 =
//     (sInsetX + sInsetY)/√2 = b——环宽均匀。
//   - b < 1 不描边（用户裁决——阈值语义）：hasBorder = false——内
//     四点 = 外四点（fillPath 覆盖 borderPath——纯色填充）。
// - 八点模型：外四点 pN/pS/pW/pE（内接矩形四边中心）+ 内四点
//   iN/iS/iW/iE（内描边环内侧轮廓）。默认绑定即菱形形态（外点 =
//   四边中心、内点 = 外点 + 直角内缩沿轴）——菱形（非 NSWE）为
//   默认状态，无需 State。NSWE 四态各仅绑定 4 个差异值：一对隐藏
//   点（对侧外点落中心 + 其内点——内缩方向按形态，用 sharpInsetY/
//   sharpInsetX 底边内缩）+ 2 个尖角内点（底角内缩，sharpInsetX/Y
//   合成）——其余点吃默认绑定（如 N 态 iN 默认 = 顶角直角内缩，
//   恰为该态值）。states 用 when 条件（direction 比较），公式绑定
//   进各 State——表达式不含 direction（形态已由 state 编码）。
// - 内描边（双层模型）：外路径填充 borderColor（描边环）+ 内路径
//   填充 color（填充面），strokeWidth 均为 0——路径边界不含描边
//   扩展（ε=0）。
// - 命中掩码（用户裁决——禁止的是 FillContains 判定，非掩码本身）：
//   根 containmentMask = gB（RectGadget——数值矩形 contains，非路径
//   填充面判定，无 FillContains 性能代价）。命中 = 内接画布矩形
//   （三角外的左右条带被排除；精确三角判定不提供——RectGadget 仅
//   矩形 contains）。宿主 MouseArea 精确 hover 需显式挂载掩码
//   （Qt hover 分发只检查 item 自身 contains——AGENTS.md 陷阱 5）。
// - implicit 不承诺（Crystal 同哲学）：Shape 引擎在路径变化时强制
//   setImplicitSize(路径边界)（qquickshape.cpp _q_shapePathChanged——
//   Qt 6.11 实证）——三角形态下 implicit 报告半组件（如 N 态 20×10）。
//   显式默认 width/height 20 不被引擎触碰，布局一律用显式尺寸，
//   implicit 值不影响使用。

import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype HalfCrystal
    \inqmlmodule Qool
    \brief 三角版 Crystal 色块（四点模型）：\c direction 切换指向
    （Qore.N/S/W/E 为直角等腰三角形，其余值为完整菱形——默认形态）。

    四点模型取内部最大正方形四边中点（斜边 45°、对轴、画布居中）：
    外轮廓四点 = \c{(cx, north)/(east, cy)/(cx, south)/(west, cy)}。
    \c direction 决定对侧点移到中心（共线隐藏于底边中点）；中间态恒为
    菱形。任意 \c width/\c height 尺寸安全（三角形基于内部最大正方形
    居中）。默认逻辑尺寸 20×20（\c width/\c height 显式默认）。

    \section2 方向语义
    \list
    \li N/S/W/E：直角等腰三角形（对侧点移到中心，底边 = 其余三点，
        顶角（直角）位于指向侧）。
    \li 其余值（\c Unknown/对角 NW/NE/SW/SE）：完整菱形（四点全原位
        ——默认状态）。
    \endlist

    \section2 样式通道
    \list
    \li \c color（默认 Style.accent）纯色填充；\c borderColor
        （ThemeHQ.recommendForeground 自动对比）内描边环色。
    \li \c borderWidth（默认 1）：内描边环宽度——外轮廓向内缩进
        borderWidth 形成描边环（全在内侧——外轮廓无描边伸出、填充区
        内缩 borderWidth；\c borderWidth < 1 时不描边——视为 0，纯色
        填充）。内缩量随 borderWidth 线性变化（无收缩极限钳制）。
        与单层线中心描边的视觉差异 0.5px 级。
    \li \c fillGradient / \c fillItem 渐变/纹理通道（fillItem 优先）——
        Crystal 同款语义，无内置渐变逻辑。
    \endlist

    \section2 动画
    HalfCrystal 不提供方向切换动画——states 应用形态直接切换（中间态
    恒为菱形），尺寸变化同样直接跳变。

    \section2 命中掩码
    \c containmentMask = 内接画布矩形（\l {Qool::RectGadget}{RectGadget}
    gB——数值矩形 contains 判定，非 FillContains 路径填充面判定，性能
    代价可控，用户裁决）。命中 = 内接画布矩形区域（三角外的条带被排除；
    精确三角判定不提供——RectGadget 仅矩形 contains）。\b hover 需显式
    挂载：Qt 的 hover 分发只检查 item 自身的 \c contains（不检查祖先
    掩码）——宿主 MouseArea 挂 \c{containmentMask: 组件id.containmentMask}
    才获得精确 hover（anchors.fill 时本地坐标与组件一致——见 AGENTS.md
    已知陷阱 5）。

    \section2 布局与 implicit
    显式默认 \c width/\c height 20（Shape 引擎在路径变化时强制
    \c setImplicitSize(路径边界)，implicit 声明会被覆盖；显式尺寸不被
    触碰——Crystal 同机制）。三角形态下引擎 implicit = 路径边界
    （如 N 态 20×10 = 半组件）——implicit 不承诺，布局一律用显式尺寸；
    宿主按需覆盖 \c width/\c height 正常。
*/
Shape {
    id: root

    /*! \qmlproperty color 填充色，默认 Style.accent（独立使用默认自洽）。 */
    property color color: root.Style.accent
    /*! \qmlproperty color 内描边环色，默认按填充色自动对比（ThemeHQ.recommendForeground）。 */
    property color borderColor: ThemeHQ.recommendForeground(root.color)
    /*! \qmlproperty real 内描边环宽度（默认 1——外轮廓向内缩进形成描边环；\c borderWidth < 1 时不描边）。 */
    property real borderWidth: 1
    /*! \qmlproperty Gradient 渐变填充通道（默认 null——纯色；fillItem 优先于渐变）。 */
    property Gradient fillGradient: null
    /*! \qmlproperty Item 纹理填充通道（Crystal 同款语义，优先于渐变/纯色）。 */
    property Item fillItem: null
    /*! \qmlproperty int 方向（Qore.Directions）——N/S/W/E 为三角形，其余值为完整菱形（默认状态），默认 Qore.N。 */
    property int direction: Qore.N

    // 命中掩码 = gB（内接画布矩形——RectGadget 数值 contains，非
    // FillContains 路径填充面判定；机制见文件头"命中掩码"与
    // AGENTS.md 已知陷阱 5）
    containmentMask: gB

    // 默认逻辑尺寸（显式——Shape 根下 implicit 声明被引擎覆盖；机制见
    // 文件头"结构决策"与 Crystal 同款）
    width: 20
    height: 20

    // —— 几何链：pCtrl（ShapeControl——target 自动 = 根 Shape）→ gA
    // （源头）→ gB（内接画布，本地坐标——组件任意位置/父变换下渲染与
    // 几何同基准）——
    ShapeControl {
        id: pCtrl

        RectGadget {
            id: gA
        }
        RectGadget {
            id: gB
            // RectGadget x/y 固定 0（不绑定 target 位置）——maxInnerSquareRect
            // 即根内部坐标，一步直绑（坐标系语义见 qool_shapegadget_rect.cpp QDoc）
            rect: gA.maxInnerSquareRect
        }

        readonly property bool hasBorder: root.borderWidth >= 1

        readonly property real rInset: Math.SQRT2 * root.borderWidth //直角顶点内缩量
        readonly property real sInsetX: rInset + root.borderWidth //尖角斜边内缩量
        readonly property real sInsetY: root.borderWidth // 尖角高内缩量

        // —— 外四点（默认绑定 = 内接矩形四边中心——菱形形态；states
        // 覆盖各三角形态的对侧点）——
        property point pN: gB.topCenter
        property point pS: gB.bottomCenter
        property point pW: gB.leftCenter
        property point pE: gB.rightCenter

        property vector2d vN: Qt.vector2d(0, rInset)
        property vector2d vS: Qt.vector2d(0, 0 - rInset)
        property vector2d vW: Qt.vector2d(rInset, 0)
        property vector2d vE: Qt.vector2d(0 - rInset, 0)

        function move_point(p: point, v: vector2d): point {
            return Qt.point(p.x + v.x, p.y + v.y);
        }

        // b < 1 不描边：内四点 = 外四点（fillPath 覆盖 borderPath——纯色
        // 填充；false 分支取外点而非位移向量——曾误取 vN/vS/vW 向量导致
        // fillPath 塌缩到原点附近，iE 的 pE 为正确形态）
        readonly property point iN: hasBorder ? move_point(pN, vN) : pN
        readonly property point iS: hasBorder ? move_point(pS, vS) : pS
        readonly property point iW: hasBorder ? move_point(pW, vW) : pW
        readonly property point iE: hasBorder ? move_point(pE, vE) : pE
    }

    states: [
        State {
            name: "N"
            when: root.direction === Qore.N
            PropertyChanges {
                target: pCtrl
                pS: gB.center // 对侧点（南）落中心——隐藏
                vS: Qt.vector2d(0, 0 - root.borderWidth)
                vW: Qt.vector2d(sInsetX, 0 - sInsetY)
                vE: Qt.vector2d(0 - sInsetX, 0 - sInsetY)
            }
        },
        State {
            name: "S"
            when: root.direction === Qore.S
            PropertyChanges {
                target: pCtrl
                pN: gB.center // 对侧点（北）落中心——隐藏
                vN: Qt.vector2d(0, root.borderWidth)
                vW: Qt.vector2d(sInsetX, sInsetY)
                vE: Qt.vector2d(0 - sInsetX, sInsetY)
            }
        },
        State {
            name: "W"
            when: root.direction === Qore.W
            PropertyChanges {
                target: pCtrl
                pE: gB.center // 对侧点（东）落中心——隐藏
                vE: Qt.vector2d(0 - root.borderWidth, 0)
                vN: Qt.vector2d(0 - sInsetY, sInsetX)
                vS: Qt.vector2d(0 - sInsetY, 0 - sInsetX)
            }
        },
        State {
            name: "E"
            when: root.direction === Qore.E
            PropertyChanges {
                target: pCtrl
                pW: gB.center // 对侧点（西）落中心——隐藏
                vW: Qt.vector2d(root.borderWidth, 0)
                vN: Qt.vector2d(sInsetY, sInsetX)
                vS: Qt.vector2d(sInsetY, 0 - sInsetX)
            }
        }
    ]

    // —— 渲染层（双层内描边模型，strokeWidth = 0——ε=0，路径边界无
    // 描边扩展）：外路径 = 描边环（borderColor 填充）、内路径 = 填充面
    // （color 填充 + 渐变/纹理通道）——
    ShapePath {
        id: borderPath
        objectName: "borderPath" // 供 QML 测试读取渲染几何（组件内部对象零暴露原则的测试例外）
        startX: pCtrl.pN.x
        startY: pCtrl.pN.y
        PathLine {
            x: pCtrl.pE.x
            y: pCtrl.pE.y
        }
        PathLine {
            x: pCtrl.pS.x
            y: pCtrl.pS.y
        }
        PathLine {
            x: pCtrl.pW.x
            y: pCtrl.pW.y
        }
        PathLine {
            x: pCtrl.pN.x
            y: pCtrl.pN.y
        }
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.borderColor
    } //borderPath

    ShapePath {
        id: fillPath
        objectName: "fillPath" // 供 QML 测试读取内描边几何
        startX: pCtrl.iN.x
        startY: pCtrl.iN.y
        PathLine {
            x: pCtrl.iE.x
            y: pCtrl.iE.y
        }
        PathLine {
            x: pCtrl.iS.x
            y: pCtrl.iS.y
        }
        PathLine {
            x: pCtrl.iW.x
            y: pCtrl.iW.y
        }
        PathLine {
            x: pCtrl.iN.x
            y: pCtrl.iN.y
        }
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.color
        fillGradient: root.fillGradient
        fillItem: root.fillItem
    } //fillPath

    // —— 四种三角形态（when 条件激活；菱形 = 默认状态，无 State——
    // 默认绑定即菱形）。各态仅绑定 4 个差异值：一对隐藏点（对侧外点
    // 落中心 + 其内点——底边内缩，方向按形态用 sharpInsetY/X）+ 2 个
    // 尖角内点（底角内缩，sharpInsetX/Y 合成）。公式表达式不含
    // direction（形态已由 state 编码）——
} //Shape
