// 关键行为与易误解点（勿改）：
//   - setValues：鼠标先裁剪到矩形（Tools.limitNumber，矩形表面
//     不像色轮那样钳方向），再 sat = x/width、ltn = 1 - y/height；
//     hslHueF < 0（无色相）时先置 0（HSL 平面需要一个有效色相才能取色）。
//   - 双击 reset：hue < 0 → 0，然后 sat = 1、ltn = 0.5（回到"纯色中点"，
//     与 HSVWheel reset 到圆心/无彩色的语义不同）。
//   - 光标 cx/cy 由 surface.position(sat, ltn) 映射（supposedPoint），
//     与 HSVWheel 的 cursorPosition 同模式。

pragma ComponentBehavior: Bound

import QtQuick
import Qool
import "NumTools.js" as Tools
import Qool.Color

// HSL 平面取色框：HSLSurface + 矩形拖动映射 + 光标。
//
// `colorAssistant` 为数据源（默认自带）；交互期间写
// `hslSaturationF` / `hslLightnessF`（hue 由外部滑块控制，本件只取
// 饱和度与明度，并在 hue 无效时置 0）。
//
// 易误解点
// - 与 HSVWheel 不同，本件命中域无圆环钳制——鼠标在矩形内直接裁剪
//   （clamp），映射是线性平面（sat = x/w，ltn = 1 - y/h）。
// - reset 到 sat=1、ltn=0.5（纯色中点）而非圆心/无彩色——两表面
//   reset 语义不同，勿统一。
// - hue < 0 → 0 的处置同时出现在 setValues 与 reset。
Item {
    id: root

    property bool animationEnabled: root.Style.animationEnabled

    property ColorAssistant colorAssistant: ColorAssistant {}

    property bool userInteracting: mouseArea.userInteracting

    HSLSurface {
        id: surface
        hslHue: colorAssistant.hslHueF
        anchors.fill: parent
    }

    InteractingArea {
        id: mouseArea
        ColorCursor {
            id: cursor
            currentColor: colorAssistant.solidColor
            userInteracting: root.userInteracting
            animationEnabled: root.animationEnabled
        } //cursor

        function setValues() {
            let xx = Tools.limitNumber(mouseX, 0.0, mouseArea.width)
            let yy = Tools.limitNumber(mouseY, 0.0, mouseArea.height)
            let p = Qt.point(xx, yy)
            let sat = surface.saturationAt(p)
            let ltn = surface.lightnessAt(p)
            if (root.colorAssistant.hslHueF < 0)
                root.colorAssistant.hslHueF = 0
            root.colorAssistant.hslSaturationF = sat
            root.colorAssistant.hslLightnessF = ltn
        }
        // 光标定位（事件驱动——CenterPlacer 回写破坏绑定，禁止绑定 centerx）
        function updateCursor() {
            const p = surface.position(root.colorAssistant.hslSaturationF,
                                       root.colorAssistant.hslLightnessF)
            cursor.centerx = p.x
            cursor.centery = p.y
        }

        onPressed: setValues()
        onPositionChanged: if (userInteracting) {
                               setValues()
                           }
        onDoubleClicked: root.reset()
    } //mouseArea
    // —— 光标定位驱动：assistant 通道变化 → 事件驱动更新光标位置。
    // （绑定会被 CenterPlacer 回写破坏——事件驱动是定案，勿改回绑定。）
    Connections {
        target: root.colorAssistant
        function onHslSaturationFChanged() { mouseArea.updateCursor() }
        function onHslLightnessFChanged() { mouseArea.updateCursor() }
    }

    // 初始定位延迟到事件循环下一轮：ColorCursor 内 CenterPlacer 的初始
    // resync 在本组件 onCompleted 之后才执行（QML 完成时序），立即调用时
    // centery 与 position 目标同值 → 同值守卫吞掉首次写入 → 光标 y 错位。
    Component.onCompleted: Qt.callLater(function () { mouseArea.updateCursor() })

    function reset() {
        if (root.colorAssistant.hslHueF < 0)
            root.colorAssistant.hslHueF = 0
        root.colorAssistant.hslSaturationF = 1
        root.colorAssistant.hslLightnessF = 0.5
    }
}
