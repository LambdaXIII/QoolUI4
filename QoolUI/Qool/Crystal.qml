// 水晶组件：OctagonShape 特化（QoolBoxGadget cut = shortEdge/2 八点模型）。
//
// 与 v3 ColorCrystal（独立 4 点菱形 Shape）的关系与差异（刻意）：
//   - 八点模型（四角排除域的顶点）：cutSize = shortEdge/2（内部中间量
//     pCtrl.cutSize——单点定义，settings 四角绑定共享）——同一模型覆盖
//     宽六边形（w > h）/ 菱形（w = h——旋转 45° 正方形，四点重合收缩）/
//     瘦六边形（w < h——上下尖 + 左右直边）。统一 8 点路径对三种形态都
//     合法（重合/共线点是合法冗余），无需路径分支。
//   - **双层模型**（OctagonShape 边框环 + 填充环）：borderWidth（默认 1）
//     内缩环承接原单层 1px 线中心描边（视觉差异 0.5px 级：描边移至内侧、
//     填充区内缩 1px、外轮廓无描边伸出）。旧"切角极限内边缘反向三角形"警告
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

OctagonShape {
    id: root

    // 填充色，默认 Style.accent（独立使用默认自洽）
    property color color: root.Style.accent
    // 内描边环色，默认按填充色自动对比（ThemeHQ.recommendForeground）
    property color borderColor: ThemeHQ.recommendForeground(root.color)
    // 内描边环宽度（默认 1——外轮廓向内缩进形成描边环）
    property real borderWidth: 1

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
    // settings = 内部八点契约（四角 cut 恒等 = shortEdge/2 + borderWidth
    // 默认 1 内缩环 + 样式通道映射）
    control: QoolBoxShapeControl {
        target: root
        settings: QoolBoxSettings {
            cutSizeTL: pCtrl.cutSize
            cutSizeTR: pCtrl.cutSize
            cutSizeBL: pCtrl.cutSize
            cutSizeBR: pCtrl.cutSize
            borderWidth: root.borderWidth // 内缩描边环（双层模型承接描边语义）
            borderColor: root.borderColor
            fillColor: root.color
        }
    }
} //OctagonShape
