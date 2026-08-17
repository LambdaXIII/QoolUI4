// NOTE(迁移) v3 Qool.Color/_private/HSVWheel.qml 逐字迁移。
// Style 对位：v3 的 `parent?.animationEnabled ?? Style.animationEnabled` →
// v4 惯例 root.Style.animationEnabled；注释掉的 cursor 位置动画
// （BasicNumberBehavior on cx/cy）原样保留（记录 v3 禁用光标平滑动画的意图——
// 光标位置由 surface.position 映射直接驱动，不插值）。
//
// 关键行为与易误解点（勿改）：
//   - 命中域是矩形（mouseArea.containmentMask: surface，v3 原样）——
//     圆外矩形内点击会经 surface.check_point 钳到圆周方向，而非忽略。
//   - setValues：check_point 钳制 → hueAt/saturationAt → 写 hsvHueF/hsvSaturationF。
//   - 双击 reset：hue = 0、sat = 0（光标回圆心；sat = 0 时色相无意义，
//     因此 reset 后的颜色是"无彩色"——黑，视 hsvValueF 而定）。
//   - 光标 centerx/centery 绑定 mouseArea.cx/cy（surface.position 映射），
//     与 ColorSlider 场景（绑定 x/y）是 ColorCursor 的两种用法。
// 与 v3 的刻意差异：无（仅 Style 对位 + 注释）。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import Qool.Color

// HSV 色轮（v3 逐字迁移）：HSVSurface + 拖动映射 + 光标。
//
// `colorAssistant` 为数据源（默认自带）；`userInteracting` 反映拖动态。
// 交互期间写 `hsvHueF` / `hsvSaturationF`；surface 的 `hsvValue` 跟随
// `colorAssistant.hsvValueF`（明度由外部滑块控制，本件只取色相与饱和度）。
//
// 易误解点
// - reset 置 hue=0、sat=0 而非"回到默认颜色"——v3 语义（回到圆心/无彩色）。
// - 圆外点击不丢弃：矩形命中域 + keepDirectionButInCircle 钳制到圆周，
//   因此点圆角处会取到圆周上的最近色相。
Item {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property ColorAssistant colorAssistant: ColorAssistant {}

    property bool userInteracting: mouseArea.userInteracting

    HSVSurface {
        id: surface
        hsvValue: colorAssistant.hsvValueF
        anchors.fill: parent
        strokeColor: colorAssistant.recommendedForegroundColor
    }

    InteractingArea {
        id: mouseArea
        containmentMask: surface

        function setValues() {
            let p = surface.check_point(Qt.point(mouseX, mouseY))
            let hue = surface.hueAt(p)
            let sat = surface.saturationAt(p)
            colorAssistant.hsvHueF = hue
            colorAssistant.hsvSaturationF = sat
        }

        onPressed: {
            setValues()
        }

        onPositionChanged: {
            if (mouseArea.userInteracting) {
                setValues()
            }
        }

        onDoubleClicked: root.reset()

        readonly property point cursorPosition: surface.position(
                                                    root.colorAssistant.hsvHueF,
                                                    root.colorAssistant.hsvSaturationF)

        property real cx: cursorPosition.x
        property real cy: cursorPosition.y

        //        BasicNumberBehavior on cx {
        //            enabled: root.animationEnabled && (!root.userInteracting)
        //            duration: root.Style.movementDuration
        //        }
        //        BasicNumberBehavior on cy {
        //            enabled: root.animationEnabled && (!root.userInteracting)
        //            duration: root.Style.movementDuration
        //        }
        ColorCursor {
            id: cursor
            animationEnabled: root.animationEnabled
            currentColor: colorAssistant.solidColor
            userInteracting: root.userInteracting

            centerx: mouseArea.cx
            centery: mouseArea.cy
        }
    } //mouseArea

    function reset() {
        root.colorAssistant.hsvHueF = 0
        root.colorAssistant.hsvSaturationF = 0
    }
}
