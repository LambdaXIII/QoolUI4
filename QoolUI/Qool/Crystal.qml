// 水晶组件：OctagonShape 特化（QoolBoxGadget cut = shortEdge/2 八点模型）。
//
// 完整契约（八点模型/双层内描边/implicit 语义/命中掩码）见
// docs/reference/Qool/Crystal.md。

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
