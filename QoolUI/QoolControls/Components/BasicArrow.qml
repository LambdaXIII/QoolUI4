import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype BasicArrow
    \inqmlmodule Qool.Controls.Components
    \brief 方向箭头（等腰三角形）——direction 设定八个方向。

    BasicArrow 绘制一个等腰三角形（顶角为直角/钝角——非楔形），
    \c direction 决定指向（\c Qore.N/S/W/E/NW/NE/SW/SE——八方向；
    \c Qore.Unknown 为默认值——不绘制）。

    结构（两层）：外层画布（Item——承载方向旋转与样式属性）+ 内部静态
    三角形（Shape——重心对准画布中心）。方向切换 = 画布旋转（绕重心——
    位置自动正确）；宿主只需设置 \c direction，三角形指向即随之变化。

    \section1 属性文档

    \qmlproperty int BasicArrow::direction
    方向（\c Qore 方向枚举——八向 + Unknown）。Unknown（默认）不绘制；
    其余方向将画布旋转至对应角度（N=0°/E=90°/S=180°/W=270°/对角 45°族）。

    \qmlproperty color BasicArrow::fillColor
    \qmlproperty color BasicArrow::borderColor
    \qmlproperty real BasicArrow::borderWidth
    填充色/边框色/边框宽——默认跟随 \l Style 的控件组
    （controlBackgroundColor / controlBorderColor / controlBorderWidth），
    宿主可覆写。边框为 0 或负值时仅填充。

    \qmlproperty real BasicArrow::animationDuration
    方向切换的旋转动画时长（毫秒）——默认 \l Style 的 movementDuration。

    \qmlproperty bool BasicArrow::animationEnabled
    动画开关（父链继承——默认 \l Style 的 animationEnabled）：关闭时方向
    切换瞬变（无旋转过渡）。

    \section1 使用示例

    \qml
    BasicArrow {
        direction: Qore.E   // 右箭头
        anchors.centerIn: parent
    }
    \endqml
*/

Item {
    id: root

    /* 方向（Qore 八向枚举——Unknown 默认不绘制） */
    property int direction: Qore.Unknown

    /* 填充/边框（默认 Style 控件组——宿主可覆写） */
    property color fillColor: Style.controlBackgroundColor
    property color borderColor: Style.controlBorderColor
    property real borderWidth: Style.controlBorderWidth

    /* 方向切换旋转动画（时长默认 Style.movementDuration；动画开关父链
       继承 + Style 默认——显式绑定避免动态依赖 Style） */
    property real animationDuration: Style.movementDuration
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 默认尺寸（宽:高 2:1——内接等腰三角形顶角 ≈106°（钝角——非楔形）；
    // 宿主改尺寸保持 2:1 比例则顶角不变）
    implicitWidth: 12
    implicitHeight: 6

    /* 方向 → 旋转角度（基准形朝 N——画布旋转设定指向）。重心对准画布
       中心（见 Shape 顶点计算）——旋转绕重心，方向切换位置自动正确。 */
    rotation: {
        switch (root.direction) {
        case Qore.N: return 0;
        case Qore.E: return 90;
        case Qore.S: return 180;
        case Qore.W: return 270;
        case Qore.NE: return 45;
        case Qore.SE: return 135;
        case Qore.SW: return 225;
        case Qore.NW: return 315;
        }
        return 0;
    }

    // 方向切换 = 旋转过渡（无点级动画——静态三角形）
    Behavior on rotation {
        enabled: root.animationEnabled
        PropertyAnimation {
            duration: root.animationDuration
            easing.type: Easing.InOutQuad
        }
    }

    /* 静态三角形：等腰（尖在顶、底边在 3/4 高）——顶点计算使重心落在
       画布中心（(w/2, h/2)：尖 (w/2, 0)、底 (±w/2, 3h/4) → 重心
       ((w/2+0+w)/3, (0+3h/4+3h/4)/3) = (w/2, h/2)）。旋转 transformOrigin
       Center（默认）即绕重心——各方向指向正确、无位置摆动。 */
    Shape {
        anchors.fill: parent
        visible: root.direction !== Qore.Unknown
        ShapePath {
            startX: root.width / 2
            startY: 0
            PathLine { x: 0; y: 3 * root.height / 4 }
            PathLine { x: root.width; y: 3 * root.height / 4 }
            PathLine { x: root.width / 2; y: 0 }

            fillColor: root.fillColor
            strokeColor: root.borderColor
            strokeWidth: root.borderWidth
            joinStyle: ShapePath.MiterJoin
        }
    }
}
