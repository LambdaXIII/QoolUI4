import QtQuick
import QtQuick.Shapes
import Qool

/*!
    \qmltype BasicArrow
    \inqmlmodule Qool.Controls.Components
    \brief 方向箭头（等腰直角三角形）——direction 设定八个方向。

    BasicArrow 绘制一个等腰直角三角形（顶角 90°——非楔形），
    \c direction 决定指向（\c Qore.N/S/W/E/NW/NE/SW/SE——八方向；
    \c Qore.Unknown 为默认值——不绘制）。

    结构（两层）：外层画布（Item——承载方向旋转与样式属性）+ 内部静态
    三角形（Shape——重心对准画布中心）。方向切换 = 画布旋转（绕重心——
    位置自动正确）；宿主只需设置 \c direction，三角形指向即随之变化。

    边框 = 两个实心三角形叠放（大 = \c borderColor、小 = \c fillColor——
    沿角平分线内缩 \c borderWidth）——内边缘语义（描边不超出三角形边缘），
    避开 QPen 描边的 miter/join 限制。

    \section1 属性文档

    \qmlproperty int BasicArrow::direction
    方向（\c Qore 方向枚举——八向 + Unknown）。Unknown（默认）不绘制；
    其余方向将画布旋转至对应角度（N=0°/E=90°/S=180°/W=270°/对角 45°族）。

    \qmlproperty color BasicArrow::fillColor
    \qmlproperty color BasicArrow::borderColor
    \qmlproperty real BasicArrow::borderWidth
    填充色/边框色/边框宽——默认跟随 \l Style 的控件组
    （controlBackgroundColor / controlBorderColor / controlBorderWidth），
    宿主可覆写。边框宽小于 1（刻意忽略亚像素）或填充与边框同色时视为
    无边框：背景层不绘制、填充层满尺寸。

    \qmlproperty real BasicArrow::animationDuration
    方向切换的旋转动画时长（毫秒）——默认 \l Style 的 movementDuration。

    \qmlproperty bool BasicArrow::animationEnabled
    动画开关（父链继承——默认 \l Style 的 animationEnabled）：关闭时方向
    切换瞬变（无旋转过渡）。

    \section1 几何说明

    三角形基于控件内部最大正方形（边长 s = min(width, height)）绘制：
    顶角 90° 的等腰直角三角形（底 = s、高 = s/2），重心精确落在画布中心
    （旋转绕重心）；整体缩放 0.949 使外接圆等于画布内切圆——旋转任意
    方向均不超出控件范围。默认尺寸为正方形（12×12）——保持 1:1 比例时
    三角形形态不变。

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
    property color fillColor: Style.accent
    property color borderColor: Style.controlBorderColor
    property real borderWidth: Style.controlBorderWidth

    /* 方向切换旋转动画（时长默认 Style.movementDuration；动画开关父链
       继承 + Style 默认——显式绑定避免动态依赖 Style） */
    property real animationDuration: Style.movementDuration
    property bool animationEnabled: parent?.animationEnabled ?? Style.animationEnabled

    // 默认尺寸：正方形（12×12）——内部最大正方形 = 整个控件
    implicitWidth: 12
    implicitHeight: 12

    /* 方向 → 旋转角度（基准形朝 N——画布旋转设定指向）。重心对准画布
       中心（见 Shape 顶点计算）——旋转绕重心，方向切换位置自动正确。 */
    rotation: {
        switch (root.direction) {
        case Qore.N:
            return 0;
        case Qore.E:
            return 90;
        case Qore.S:
            return 180;
        case Qore.W:
            return 270;
        case Qore.NE:
            return 45;
        case Qore.SE:
            return 135;
        case Qore.SW:
            return 225;
        case Qore.NW:
            return 315;
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

    /* 几何（等腰直角三角形——顶角 90°）：
       s = min(w, h)——内部最大正方形边长
       基准顶点（重心对准画布中心 (w/2, h/2)）：
         尖     (w/2, h/2 - s/3)
         底角   (w/2 ± s/2, h/2 + s/6)
         —— 顶角 = 2·atan((s/2)/(s/2)) = 90°；重心 = ((w/2+0+w)/3,
            (h/2-s/3 + 2·(h/2+s/6))/3) = (w/2, h/2) ✓
       旋转安全：重心到最远顶点（底角）= s·√10/6 ≈ 0.527s > 画布内切圆
       半径 s/2——整体缩放 0.949（0.5/0.527）使外接圆 = 内切圆，
       旋转任意方向不超出控件。
       边框（环带）：大三角形（borderColor 实心）+ 小三角形（fillColor
       实心——沿角平分线内缩 borderWidth：尖角 90° → 内移 √2·t、底角 45°
       → 内移 t/sin(22.5°)≈2.613·t——垂直边距均匀为 t）。 */
    readonly property real s: Math.min(root.width, root.height)
    readonly property real k: 0.949
    readonly property point apex: Qt.point(root.width / 2, root.height / 2 - root.s * k / 3)
    readonly property point baseL: Qt.point(root.width / 2 - root.s * k / 2, root.height / 2 + root.s * k / 6)
    readonly property point baseR: Qt.point(root.width / 2 + root.s * k / 2, root.height / 2 + root.s * k / 6)

    // 边框可见性（统一优化条件）：borderWidth < 1（刻意忽略亚像素）或
    // 填充与边框同色（背景层被前景完全覆盖——环带同色不可见）→ 无边框
    // 路径：背景层不绘制、前景层满尺寸（少一层 ShapePath）
    readonly property bool showBorder: root.borderWidth >= 1 && root.fillColor !== root.borderColor

    // 小三角形（fill 层）：沿角平分线内缩 borderWidth（垂直边距均匀）。
    // 无边框路径（showBorder false——亚像素或同色）不内缩（满尺寸）。
    // 尖角 90°——角平分线 = 对称轴（竖直向下）——内移 √2·t
    readonly property point innerApex: Qt.point(root.apex.x, root.apex.y + (root.showBorder ? root.borderWidth : 0) * Math.SQRT2)
    // 底角 45°——角平分线方向 = 底边方向 (1,0) 与斜边方向 (√2/2, √2/2) 的
    // 单位向量和 = (cos22.5°, sin22.5°) ≈ (0.924, 0.383)——内移 t/sin(22.5°)
    readonly property point innerBaseL: {
        const t = root.showBorder ? root.borderWidth : 0;
        const d = t / Math.sin(Math.PI / 8);
        return Qt.point(root.baseL.x + 0.924 * d, root.baseL.y + 0.383 * d);
    }
    readonly property point innerBaseR: {
        const t = root.showBorder ? root.borderWidth : 0;
        const d = t / Math.sin(Math.PI / 8);
        return Qt.point(root.baseR.x - 0.924 * d, root.baseR.y + 0.383 * d);
    }

    // 两个重叠 Shape（背景 = 边框层、前景 = 填充层）。无边框路径
    // （showBorder false——亚像素或同色）时背景 Shape 整体 visible: false
    // ——真不渲染（Shape 是 Item——透明填充的路径仍参与 Shape 处理，
    // 达不到省渲染的效果）
    Shape {
        anchors.fill: parent
        visible: root.showBorder && root.direction !== Qore.Unknown

        // 大三角形（边框层——borderColor 实心）
        ShapePath {
            startX: root.apex.x
            startY: root.apex.y
            PathLine {
                x: root.baseL.x
                y: root.baseL.y
            }
            PathLine {
                x: root.baseR.x
                y: root.baseR.y
            }
            PathLine {
                x: root.apex.x
                y: root.apex.y
            }
            fillColor: root.borderColor
        }
    }

    Shape {
        anchors.fill: parent
        visible: root.direction !== Qore.Unknown

        // 小三角形（填充层——fillColor 实心——showBorder 时沿角平分线
        // 内缩 borderWidth，否则满尺寸）
        ShapePath {
            startX: root.innerApex.x
            startY: root.innerApex.y
            PathLine {
                x: root.innerBaseL.x
                y: root.innerBaseL.y
            }
            PathLine {
                x: root.innerBaseR.x
                y: root.innerBaseR.y
            }
            PathLine {
                x: root.innerApex.x
                y: root.innerApex.y
            }
            fillColor: root.fillColor
        }
    }
}
