// 水晶组件：OctagonShape 特化（QoolBoxGadget cut = shortEdge/2 八点模型）。
//
// 与 v3 ColorCrystal（独立 4 点菱形 Shape）的关系与差异（刻意）：
//   - 八点模型（四角排除域的顶点）：cutSize = shortEdge/2（内部中间量
//     pCtrl.cutSize——单点定义，settings 四角绑定共享）——同一模型覆盖
//     宽六边形（w > h）/ 菱形（w = h——旋转 45° 正方形，四点重合收缩）/
//     瘦六边形（w < h——上下尖 + 左右直边）。统一 8 点路径对三种形态都
//     合法（重合/共线点是合法冗余），无需路径分支。
//   - **双层模型**（OctagonShape 边框环 + 填充环）：borderWidth = 1 内缩
//     环承接原单层 1px 线中心描边（视觉差异 0.5px 级：描边移至内侧、填充
//     区内缩 1px、外轮廓无描边伸出）。旧"切角极限内边缘反向三角形"警告
//     基于已删除的 pCtrl 内弧算法——QoolBoxGadget 半平面交集模型下菱形/
//     瘦六边形均为合法极限形态（tst_qoolboxgadget shrink_diamond_limit
//     用例固化）。
//   - 轨道与手柄同模型：Slider 的轨道（宽条六边形）与手柄（方形菱形）
//     斜边斜率一致——天然对齐（水晶顶点贴轨道斜边——外轮廓位置不变，
//     对齐契约保持）。
//   - 菱形左上角锚定（中心 = (width/2, height/2)），定位方式与普通 Item
//     一致（v3 ColorCrystal 的"中心在原点"仅被 Color 模块 ColorCursor
//     依赖，Color 侧保留原私有件；本件为 Qool 公开件）。
//   - **精确命中掩码**（QoolBoxShapeControl::contains——外接矩形内四角
//     切角域排除，斜边与八点顶点命中）：独立使用场景命中域与可见形状
//     一致。
//
// 结构决策（root = OctagonShape，Shape 根）：双层模型 strokeWidth = 0，
// 路径边界 = 组件几何（ε=0）——Shape 引擎 setImplicitSize 的值为不动点，
// 无 implicit 正反馈环（单层 + 1px 线中心描边模型的 ε>0 发散问题随双层
// 模型消失，Item 包裹不再需要）。默认逻辑尺寸 = width/height 显式 20
// （implicitWidth 声明会被引擎无条件覆盖；显式 width/height 不被触碰，
// 初始路径 20×20 → 引擎 implicit 20 → 布局 preferred 20）。
//
// control/settings：required control 由组件内默认实例化满足（宿主可替换
// ——高级用法，QoolBox 同哲学）；settings 为内部八点契约（四角 cut 恒 =
// shortEdge/2——经 pCtrl.cutSize 内部中间量单点定义；宿主无法经组件 id
// 访问子对象，零暴露；物理上 control.settings 可触及，文档契约约束勿改）。

import QtQuick
import Qool

/*!
    \qmltype Crystal
    \inqmlmodule Qool
    \brief 水晶六边形色块（八点模型）：\c width > \c height 为六边形、
    \c width = \c height 为菱形（旋转 45° 的正方形）、\c width < \c height
    为瘦六边形（上下尖 + 左右直边）。左上角锚定。

    \l {Qool::OctagonShape}{OctagonShape} 特化形态：内部注入
    \l {Qool::QoolBoxShapeControl}{QoolBoxShapeControl}（target = 自身），
    settings 四角切角恒绑定 shortEdge/2（内部中间量单点定义——八点几何
    契约），\c borderWidth 固定 1（内缩描边环）。三种形态即
    \l {Qool::QoolBoxGadget}{QoolBoxGadget} 的 cut = shortEdge/2 特化
    （半平面交集模型下退化形态合法——菱形/瘦六边形均为定义良好的极限）。

    \section2 用法
    \list
    \li 手柄（方形）：默认逻辑尺寸 20×20（\c width/\c height 显式默认——
        implicit 由引擎驱动 = 路径边界，随实际几何）；轨道（宽条）：覆盖
        \c width/\c height（宽六边形）。Slider 的轨道与手柄均用本件，斜边
        斜率一致天然对齐。
    \li \c color 为纯色填充；\c fillGradient / \c fillItem 为填充通道
        （\l {Qool::OctagonShape}{OctagonShape} 同款语义——fillItem 优先）。
    \li 渐变锚点（左上/右上斜边内侧交点）不另暴露——宿主按
        \c{(width/2, height/2)} 与 \c{(width - width/2, height/2)} 自算
        （Slider 即此）。
    \endlist

    \section2 描边
    \c borderWidth 固定 1：内缩描边环（全在内侧——外轮廓无描边伸出，
    填充区内缩 1px）。\c strokeColor 即环色（单层线中心描边的语义由
    双层模型承接，视觉差异 0.5px 级）。

    \section2 命中掩码
    掩码委托 \l {Qool::QoolBoxShapeControl}{QoolBoxShapeControl} 的
    \c contains（外接矩形内四角切角域排除，斜边与顶点命中——开集语义，
    与可见形状一致）。\b hover 需显式挂载：Qt 的 hover 分发只检查 item
    自身的 \c contains（不检查祖先掩码）——宿主 MouseArea 挂
    \c{containmentMask: 组件id.containmentMask} 才获得精确 hover（与
    HalfCrystal 同机制，用法见 HalfCrystal「命中掩码」章节）。

    \section2 低级组成件契约
    \c control 为 OctagonShape 的 required 属性（本组件内默认实例化）——
    替换 control 属高级用法（自定义几何源）；\c settings 为内部八点契约
    （四角 cut 恒 = shortEdge/2），直接修改破坏形态自洽——Crystal 不提供
    settings 配置面。
*/
OctagonShape {
    id: root

    /*! \qmlproperty color 填充色，默认 Style.accent（独立使用默认自洽）。 */
    property color color: root.Style.accent
    /*! \qmlproperty color 描边色，默认按填充色自动对比（ThemeHQ.recommendForeground）。 */
    property color strokeColor: ThemeHQ.recommendForeground(root.color)

    // 默认逻辑尺寸（机制见文件头"结构决策"——implicit 声明被引擎覆盖，
    // 显式 width/height 不被触碰；引擎 implicit = 路径边界 = 几何）
    width: 20
    height: 20

    // 内部中间量：cutSize = shortEdge/2（八点几何契约单点定义——settings
    // 四角绑定共享；宿主无法经组件 id 访问子对象，零暴露）
    QtObject {
        id: pCtrl
        readonly property real cutSize: Math.min(root.width, root.height) / 2
    }

    // required control 组件内默认实例化满足（宿主可替换——高级用法）；
    // settings = 内部八点契约（四角 cut 恒等 = shortEdge/2 + borderWidth 1
    // 内缩环 + 样式通道映射）
    control: QoolBoxShapeControl {
        target: root
        settings: QoolBoxSettings {
            cutSizeTL: pCtrl.cutSize
            cutSizeTR: pCtrl.cutSize
            cutSizeBL: pCtrl.cutSize
            cutSizeBR: pCtrl.cutSize
            borderWidth: 1 // 内缩描边环（双层模型承接 1px 描边语义）
            borderColor: root.strokeColor
            fillColor: root.color
        }
    }
} //OctagonShape
