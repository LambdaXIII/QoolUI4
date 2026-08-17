// NOTE(迁移) v3 Qool.Color/_private/ColorCrystal.qml 逐字迁移。
// 拍平点：v3 的 ShapeHelper（qool_shapehelper.cpp，v4 已移除）在本文件内联为
// pShape（四个顶点 pointA..pointD 是 v3 ShapeHelper 同名属性的逐字推导）。
// 与 v3 的刻意差异：无（仅 ShapeHelper 内联 + 补注释）。
//
// 关键几何（易误解，勿改）：
//   - 菱形绘制在"自身原点周围"：pointA(0, -r)、pointB(r, 0)、pointC(0, r)、
//     pointD(-r, 0)，即菱形中心 = 组件 (0,0)，而不是左上角 (0,0)。
//     因此消费方（ColorCursor）把本件 x/y 定位到"想要菱形中心所在的位置"——
//     ColorCursor 中 crystal.x = parent.width/2、y = parent.height/2。
//   - containmentMask 用 v4 Crystal4ContainmentMask，centerPoint 默认 (0,0)，
//     与"菱形中心在掩码原点"天然重合（v4 Crystal4ContainmentMask 的文档亦
//     明确 ColorCrystal 依赖此默认，勿传 centerPoint）。
//   - strokeWidth 固定 1（v3 原样）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

// 水晶4菱形色块（v3 逐字迁移）：以 `size` 为外接框的菱形，中心在组件原点。
//
// `color` / `strokeColor` 分别控制填充与描边；默认 `size` 25。
// 菱形中心在组件坐标原点（见文件头注释），消费方以 x/y 把中心放到目标位置。
//
// 易误解点
// - 菱形中心不在左上角——若误以为菱形锚定 (0,0) 左上，会把它放偏半个对角线。
// - containmentMask 的默认 centerPoint (0,0) 是刻意依赖（与 v3 一致），
//   菱形命中域 = 掩码外接框的内接菱形。
Shape {
    id: root

    property real size: 25
    property color color
    property color strokeColor

    QtObject {
        id: pShape
        readonly property real radius: root.size / 2
        readonly property point pointA: Qt.point(0, 0 - radius)
        readonly property point pointB: Qt.point(radius, 0)
        readonly property point pointC: Qt.point(0, radius)
        readonly property point pointD: Qt.point(0 - radius, 0)
    } //pShape

    ShapePath {
        startX: pShape.pointA.x
        startY: pShape.pointA.y
        PathLine {
            x: pShape.pointB.x
            y: pShape.pointB.y
        }
        PathLine {
            x: pShape.pointC.x
            y: pShape.pointC.y
        }
        PathLine {
            x: pShape.pointD.x
            y: pShape.pointD.y
        }
        PathLine {
            x: pShape.pointA.x
            y: pShape.pointA.y
        }
        fillColor: root.color
        strokeColor: root.strokeColor
        strokeWidth: 1
    }

    containmentMask: Crystal4ContainmentMask {
        width: root.size
        height: root.size
    }
}
