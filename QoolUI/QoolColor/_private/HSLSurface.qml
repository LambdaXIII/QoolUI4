// NOTE(迁移) v3 Qool.Color/_private/HSLSurface.qml 逐字迁移。
// Style 对位：v3 的 `parent?.animationEnabled ?? Style.animationEnabled` →
// v4 惯例 root.Style.animationEnabled。
//
// 关键行为与易误解点（勿改）：
//   - 坐标语义：sat = x / width（左 0 → 右 1）；lightness = 1 - y / height
//     （y 向下，顶 = 1 白，底 = 0 黑）。position(sat, ltn) 是其反函数。
//   - 三层 Rectangle 叠加（顺序即 z 序）：
//       1. satBox：水平渐变，从 hsl(hue, 0, 0.5)（50% 灰）到 standardColor
//          （hsl(hue, 1, 0.5)）——色相 × 饱和度的平面；
//       2. lightnessBox：垂直渐变 白 → 透明 → 黑（中间透明露出 satBox）——
//          明度轴；
//       3. strokeBox（z: -10，垫底）：垂直渐变 黑 → standardColor，其第二个
//          GradientStop 的 color 带 BasicColorBehavior 动画（hue 变化时
//          垫底色平滑过渡）。
//   - 三层都 anchors.margins: 1 + radius: 5（圆角内缩 1px，v3 原样）。
//   - hslHue 变化时 satBox/lightnessBox/strokeBox 颜色由绑定跟随
//     （GradientStop color 绑定）。
// 与 v3 的刻意差异：无（仅 Style 对位 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// HSL 颜色平面（v3 逐字迁移）：色相固定、饱和度×明度的二维表面。
//
// `hslHue` 决定整个平面的色相；`saturationAt` / `lightnessAt` /
// `position` 提供坐标↔HSL 映射（消费方 HSLBox 使用）。
//
// 易误解点
// - 明度 y 轴向下：y = 0 是"顶/白/明度 1"，与直觉"上小下大"相反，
//   映射公式 1 - y/height 是刻意设计，勿改。
// - 中间层 lightnessBox 用"白→透明→黑"而非"白→中灰→黑"——透明层露出
//   satBox 的色相×饱和度面，这是 v3 的分层技巧。
// - strokeBox 的 z 为 -10 垫底（黑→standardColor 渐变），其颜色动画
//   只作用于第二个 GradientStop（v3 原样，行为在 Qt6 下与 v3 一致）。
Item {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property real hslHue: 0.25
    readonly property color standardColor: Qt.hsla(hslHue, 1, 0.5, 1)

    property real radius: 5

    function saturationAt(point) {
        return point.x / root.width
    }

    function lightnessAt(point) {
        return 1 - point.y / root.height
    }

    function position(sat, lightness) {
        let x = root.width * sat
        let y = root.height * (1 - lightness)
        return Qt.point(x, y)
    }

    Rectangle {
        id: satBox
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius
        border.width: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 1.0
                color: root.standardColor
            }
            GradientStop {
                position: 0.0
                color: Qt.hsla(root.hslHue, 0, 0.5, 1)
            }
        }
    }

    Rectangle {
        id: lightnessBox
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius
        border.width: 0
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0
                color: Qt.hsla(root.hslHue, 1, 1, 1)
            }
            GradientStop {
                position: 0.5
                color: "transparent"
            }

            GradientStop {
                position: 1
                color: Qt.hsla(root.hslHue, 0, 0, 1)
            }
        }
    }

    Rectangle {
        id: strokeBox
        z: -10
        anchors.fill: parent
        border.width: 0
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0
                color: "black"
            }

            GradientStop {
                position: 1
                color: root.standardColor
                BasicColorBehavior on color {
                    enabled: root.animationEnabled
                }
            }
        }
    }
}
