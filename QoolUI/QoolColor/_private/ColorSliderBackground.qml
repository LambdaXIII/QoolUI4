// 关键几何（易误解，勿改）：
//   - 形状是"上下切角"的六边形：左/右两边斜 45°，顶部/底部是水平短边。
//     pointA(0, cutSize) → B(cutSize, 0) → C(w-cutSize, 0) → D(w, cutSize)
//     → E(w-cutSize, h) → F(cutSize, h) → A。
//   - leftPoint/rightPoint（= pShape.point0/point1）是轨道中线上
//     切角内侧的两个点：(cutSize, cutSize) 与 (w-cutSize, cutSize)。
//     消费方（ColorSlider 变体）用它作 LinearGradient 的 x1/y1/x2/y2——
//     让渐变只横贯"有效轨道段"，不染到斜切角外。
//   - ShapePath 的 fill/stroke 默认值由消费方经别名覆盖（fillGradient/
//     fillColor/strokeColor/strokeWidth）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

// 滑块轨道背景（六边形）：切角尺寸固定为高度一半。
//
// `strokeWidth` / `strokeColor` / `fillColor` / `fillGradient` 为 ShapePath
// 的透传别名；`leftPoint` / `rightPoint` 只读，供渐变锚定有效轨道段。
//
// 易误解点
// - 切角 = 高度一半（`cutSize`: height / 2），改变高度会同时改变切角，
//   六边形始终内切于矩形。
// - leftPoint/rightPoint 是渐变锚点而非边框点——消费方渐变
//   （ColorSlider_Hue 彩虹等）的 x1/y1/x2/y2 直接取它们，勿改为顶点。
Shape {
    id: root

    implicitWidth: 20
    implicitHeight: 10

    property alias strokeWidth: mainPath.strokeWidth
    property alias strokeColor: mainPath.strokeColor
    property alias fillColor: mainPath.fillColor
    property alias fillGradient: mainPath.fillGradient
    readonly property point leftPoint: pShape.point0
    readonly property point rightPoint: pShape.point1

    QtObject {
        id: pShape
        readonly property real cutSize: root.height / 2

        readonly property point pointA: Qt.point(0, cutSize)
        readonly property point pointB: Qt.point(cutSize, 0)
        readonly property point pointC: Qt.point(root.width - cutSize, 0)
        readonly property point pointD: Qt.point(root.width, cutSize)
        readonly property point pointE: Qt.point(root.width - cutSize, root.height)
        readonly property point pointF: Qt.point(cutSize, root.height)

        readonly property point point0: Qt.point(pointB.x, pointA.y)
        readonly property point point1: Qt.point(pointC.x, pointA.y)
    } //pShape

    ShapePath {
        id: mainPath
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
            x: pShape.pointE.x
            y: pShape.pointE.y
        }

        PathLine {
            x: pShape.pointF.x
            y: pShape.pointF.y
        }

        PathLine {
            x: pShape.pointA.x
            y: pShape.pointA.y
        }
    }
}
