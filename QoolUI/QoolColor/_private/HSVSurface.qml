// 刻意差异（防审查误判，勿改）：
//   1. 本件没有圆形成员掩码——`containmentMask: circler` 曾是类型不匹配的
//      死代码（CircleGadget 是 QObject 而非 Item，QML 运行时报错并跳过），
//      已删除；命中域不变：消费方 InteractingArea 以整个 surface 矩形为掩码，
//      圆外点击由 check_point/keepDirectionButInCircle 钳制。
//
// 关键数学（易误解，勿改）：
//   - 圆心 = (w/2, h/2)；半径 = 内切圆 min(w,h)/2（非外接圆）。
//   - radian(vec)：atan(y/x) + 象限修正（q2/q3 加 π，q4 加 2π）——返回 [0, 2π)，
//     0 rad 指向 +x，y 向下屏幕坐标下正向为顺时针。
//   - angle(rad) = cleanRadian(rad) / 2π ∈ [0, 1)。
//   - hueAt：hue = angle - 0.75（1 取模）——hue 0（红）位于圆顶（与
//     ConicalGradient 的 angle: 90 起始配合，勿改）。
//   - saturationAt = clamp(centerDistance / radius, 0, 1)。
//   - position(hue, sat)：sat === 0 时返回圆心；否则 rad = (hue - 0.25)·2π，
//     dist = sat·radius，向量 (cos·d, sin·d) 平移圆心。
//   - check_point = keepDirectionButInCircle：圆外点保持方向钳到圆周
//     （ratio = radius/dist，同方向缩放）。
//   - 三层 ShapePath：hueSurface（ConicalGradient，angle 90，stops 0.99→0
//     反向排布使 0.99 在角度 0 附近）、satSurface（RadialGradient 白→透明）、
//     valueSurface（黑色 fillColor alpha = 1 - hsvValue，描边 strokeColor）。
// 渐变坐标是像素坐标（Shape 自身坐标系，与 DialRangeArc 同款用法）。

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Qool
import Qool.Color

// HSV 色轮表面：色相环 + 饱和度径向 + 明度压暗三层叠加。
//
// 消费方（HSVWheel）通过 `hueAt` / `saturationAt` / `position` /
// `check_point` 做坐标↔HSV 映射；`hsvValue` 控制黑色压暗层的 alpha。
//
// 易误解点
// - 色相映射 hue = angle - 0.75（红在圆顶）与 position 的 (hue - 0.25)·2π
//   是互逆的一对，改一个必须改另一个，否则光标与点击位置错位。
// - 半径是内切圆 min(w,h)/2——非方形容器下色轮是内切圆而非外接圆。
// - `hsvValue` = 1 时黑色层 alpha 0（不压暗）；`hsvValue` 越小压暗越重
//   （fillColor 黑色 + alpha 1 - hsvValue）。
// - 本件没有圆形成员掩码——命中域由消费方的矩形 surface 掩码决定
//   （CircleGadget containmentMask 死代码说明见文件头注释）。
Shape {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    readonly property real radius: pMath.radius
    property color strokeColor: root.Style.text
         property real hsvValue: 1
     // 压暗层契约点（value → 压暗层 alpha 派生——公开视觉契约的测试例外，
     // Shape 内 ShapePath 不可经 children 遍历，直接暴露只读派生作断言锚）。
     readonly property real darkAlpha: 1 - root.hsvValue

    antialiasing: true

    BasicColorBehavior on strokeColor {
        enabled: root.animationEnabled
    }

    function hueAt(point) {
        const p_rad = pMath.centerRadian(point)
        let p_angle = pMath.angle(p_rad)
        if (p_angle < 0)
            p_angle += 1
        let hue = p_angle - 0.25 - 0.5
        if (hue < 0)
            hue += 1
        return hue
    }

    function saturationAt(point) {
        const p_dist = pMath.centerDistance(point)
        const sat = Qore.bound(0, p_dist / pMath.radius, 1)
        return sat
    }

    function position(hue, sat) {
        if (sat === 0)
            return pMath.center
        let rad = (hue - 0.25) * pMath.radianForCircle()
        let dist = sat * pMath.radius
        let vec = pMath.vector(rad, dist)
        return pMath.pointFromCenterVector(vec)
    }

    function check_point(point) {
        return pMath.keepDirectionButInCircle(point)
    }

    // 圆几何数学内联实现：象限修正、环绕、向量与钳制。
    QtObject {
        id: pMath
        readonly property real radius: Math.min(root.width, root.height) / 2
        readonly property point center: Qt.point(root.width / 2, root.height / 2)

        function cleanRadian(rad) {
            while (rad >= Math.PI * 2 || rad < 0) {
                if (rad >= Math.PI * 2)
                    rad -= Math.PI * 2
                if (rad < 0)
                    rad += Math.PI * 2
            }
            return rad
        }

        function quadrant(x, y) {
            if (x >= 0 && y >= 0)
                return 1
            if (x < 0 && y >= 0)
                return 2
            if (x < 0 && y < 0)
                return 3
            if (x >= 0 && y < 0)
                return 4
            return 0
        }

        function radian(vec) {
            const atan = Math.atan(vec.y / vec.x)
            const q = quadrant(vec.x, vec.y)
            if (q === 2 || q === 3)
                return atan + Math.PI
            if (q === 4)
                return atan + Math.PI * 2
            return atan
        }

        function angle(rad) {
            return cleanRadian(rad) / (Math.PI * 2)
        }

        function radianForCircle() {
            return Math.PI * 2
        }

        function vector(rad, distance) {
            if (distance === 0)
                return Qt.point(0, 0)
            rad = cleanRadian(rad)
            return Qt.point(distance * Math.cos(rad),
                            distance * Math.sin(rad))
        }

        function distance(x, y) {
            return Math.pow(Math.pow(x, 2) + Math.pow(y, 2), 0.5)
        }

        function centerVector(point) {
            return Qt.point(point.x - center.x, point.y - center.y)
        }

        function centerDistance(point) {
            const v = centerVector(point)
            return distance(v.x, v.y)
        }

        function centerRadian(point) {
            return radian(centerVector(point))
        }

        function pointFromCenterVector(vec) {
            return Qt.point(center.x + vec.x, center.y + vec.y)
        }

        function keepDirectionButInCircle(point) {
            const dist = centerDistance(point)
            if (dist <= radius)
                return point
            const ratio = radius / dist
            const v = centerVector(point)
            return pointFromCenterVector(Qt.point(v.x * ratio, v.y * ratio))
        }
    } //pMath

    ShapePath {
        id: hueSurface
        startX: pMath.center.x - pMath.radius
        startY: pMath.center.y
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x + pMath.radius
            y: pMath.center.y
        }
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x - pMath.radius
            y: pMath.center.y
        }
        strokeWidth: 0
        fillGradient: ConicalGradient {
            angle: 90
            centerX: pMath.center.x
            centerY: pMath.center.y
            GradientStop {
                position: 0.99
                color: Qt.hsva(0, 1, 1, 1)
            }
            GradientStop {
                position: 0.9
                color: Qt.hsva(0.1, 1, 1, 1)
            }
            GradientStop {
                position: 0.8
                color: Qt.hsva(0.2, 1, 1, 1)
            }
            GradientStop {
                position: 0.7
                color: Qt.hsva(0.3, 1, 1, 1)
            }
            GradientStop {
                position: 0.6
                color: Qt.hsva(0.4, 1, 1, 1)
            }
            GradientStop {
                position: 0.5
                color: Qt.hsva(0.5, 1, 1, 1)
            }
            GradientStop {
                position: 0.4
                color: Qt.hsva(0.6, 1, 1, 1)
            }
            GradientStop {
                position: 0.3
                color: Qt.hsva(0.7, 1, 1, 1)
            }
            GradientStop {
                position: 0.2
                color: Qt.hsva(0.8, 1, 1, 1)
            }
            GradientStop {
                position: 0.1
                color: Qt.hsva(0.9, 1, 1, 1)
            }
            GradientStop {
                position: 0
                color: Qt.hsva(1, 1, 1, 1)
            }
        }
    }

    ShapePath {
        id: satSurface
        startX: pMath.center.x - pMath.radius
        startY: pMath.center.y
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x + pMath.radius
            y: pMath.center.y
        }
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x - pMath.radius
            y: pMath.center.y
        }

        fillGradient: RadialGradient {
            centerX: pMath.center.x
            centerY: pMath.center.y
            focalX: centerX
            focalY: centerY
            centerRadius: pMath.radius
            GradientStop {
                position: 0
                color: "white"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

              ShapePath {
         id: valueSurface
         startX: pMath.center.x - pMath.radius
        startY: pMath.center.y
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x + pMath.radius
            y: pMath.center.y
        }
        PathArc {
            radiusX: pMath.radius
            radiusY: pMath.radius
            x: pMath.center.x - pMath.radius
            y: pMath.center.y
        }
        strokeWidth: 1
        strokeColor: root.strokeColor
        fillColor: Qt.rgba(0, 0, 0, 1 - root.hsvValue)
    }
}
