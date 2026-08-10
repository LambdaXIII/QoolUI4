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

    结构：外层根 Item（稳定——rotation 留给宿主）+ 内层画布（Item——
    承载方向旋转）+ 图形逻辑（ShapeControl 挂 CircleGadget 与双
    TriangleGadget）+ 两个重叠 Shape（背景 = 边框层、前景 = 填充层）。
    方向切换 = 内层画布旋转（绕重心——位置自动正确）；宿主只需设置
    \c direction，三角形指向即随之变化（组件自身不旋转）。

    命中：\c containmentMask 为 QtObject 包装——\c contains 仅以画布
    内接圆（\c s/2——旋转安全半径）判定。刻意简化：本组件主要用途为
    小尺寸箭头，精确三角形命中过度且无意义——圆判定宽松、旋转不变
    （无需坐标变换）。

    边框 = 两个重叠 Shape（大 = \c borderColor 实心、小 = \c fillColor
    实心——每点沿邻边方向分量内缩 \c borderWidth）——内边缘语义（描边不
    超出三角形边缘）；前景 Shape 坐标挂 Behavior——\c borderWidth 等
    动态变化时平滑过渡。

    \section1 属性文档

    \qmlproperty int BasicArrow::direction
    方向（\c Qore 方向枚举——八向 + Unknown）。Unknown（默认）不绘制；
    其余方向将画布旋转至对应角度（SW 基准 0°，顺时针 45° 步进：
    SW=0/S=45/SE=90/E=135/NE=180/N=225/NW=270/W=315）。

    \qmlproperty color BasicArrow::fillColor
    \qmlproperty color BasicArrow::borderColor
    \qmlproperty real BasicArrow::borderWidth
    填充色/边框色/边框宽——默认跟随 \l Style 的控件组
    （controlBackgroundColor / controlBorderColor / controlBorderWidth），
    宿主可覆写。边框宽小于 1（刻意忽略亚像素）或填充与边框同色时视为
    无边框：背景层不绘制、填充层满尺寸。

    \qmlproperty real BasicArrow::animationDuration
    方向切换的旋转动画时长（毫秒）——默认 \l Style 的 movementDuration。
    方向切换沿最近角度路径旋转（如 NW→SW 走顺时针 90°，而非反向
    270° 大圈——BasicRotationBehavior 等价角判定）。

    \qmlproperty bool BasicArrow::animationEnabled
    动画开关（父链继承——默认 \l Style 的 animationEnabled）：关闭时方向
    切换瞬变（无旋转过渡）。

    \section1 几何说明

    基准方向 SW（尖朝左下）——直角在尖、两条直角边对齐坐标轴（水平/
    垂直）——顶点位置与内缩计算极简。三角形基于控件内部最大正方形
    （边长 s = min(width, height)）绘制，重心精确落在画布中心（旋转绕
    重心）；直角边 a = 0.671·s 使外接圆等于画布内切圆——旋转任意方向
    均不超出控件范围。默认尺寸为正方形（12×12）。

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

    /* 图形逻辑（ShapeControl 体系）：
       s = min(w, h)——内部最大正方形边长
       直角边 a = 0.671·s（重心到最远顶点（直角边端点）= a·√5/3 ≈ 0.745a
       = 画布内切圆半径 s/2——旋转任意方向不超出控件）。
       基准方向 SW（尖朝左下）：重心对准画布中心 (w/2, h/2)——尖在
       重心左下 (a/3, a/3)，直角边沿坐标轴（水平向右 a、垂直向上 a）：
         尖      (w/2 - a/3, h/2 + a/3)
         水平端点 (尖.x + a, 尖.y)
         垂直端点 (尖.x, 尖.y - a) */
    readonly property real s: Math.min(root.width, root.height)
    readonly property real a: 0.671 * root.s

    // 边框可见性（统一优化条件）：borderWidth < 1（刻意忽略亚像素）或
    // 填充与边框同色（背景层被前景完全覆盖——环带同色不可见）→ 无边框
    // 路径：背景 Shape 不渲染、前景层满尺寸
    readonly property bool showBorder: root.borderWidth >= 1 && root.fillColor !== root.borderColor

    ShapeControl {
        id: shapeCtrl

        // 画布圆（外接圆 = 内切圆——contains 快速粗判）
        CircleGadget {
            id: circleG
            center: Qt.point(root.width / 2, root.height / 2)
            radius: root.s / 2
        }

        // 大三角形（理想大小——SW 基准三点）
        TriangleGadget {
            id: triOuter
            pointA: Qt.point(root.width / 2 - root.a / 3, root.height / 2 + root.a / 3)
            pointB: Qt.point(root.width / 2 - root.a / 3 + root.a, root.height / 2 + root.a / 3)
            pointC: Qt.point(root.width / 2 - root.a / 3, root.height / 2 + root.a / 3 - root.a)
        }

        // 小三角形（微缩版——三点绑定大三角形 + 内缩映射）。内缩沿
        // 角平分线/邻边方向（参考 QoolBoxShapeControl 的"每点独立分量"
        // 算法——平行移动不错位；非直角（底角 45°）需 22.5° 修正）：
        //   尖（直角——角平分线 45°）：(+t, -t)（沿斜边方向 NE——到两
        //     直角边各 t）
        //   水平端点（水平边 y=-t 与内缩斜边交点）：(-(1+√2)t, -t)
        //   垂直端点（垂直边 x=t 与内缩斜边交点）：(+t, +(1+√2)t)
        //   （两底角均向三角形内部——垂直端点在顶部，内缩向右下）
        TriangleGadget {
            id: triInner
            pointA: Qt.point(triOuter.pointA.x + (root.showBorder ? root.borderWidth : 0), triOuter.pointA.y - (root.showBorder ? root.borderWidth : 0))
            pointB: Qt.point(triOuter.pointB.x - (root.showBorder ? (1 + Math.SQRT2) * root.borderWidth : 0), triOuter.pointB.y - (root.showBorder ? root.borderWidth : 0))
            pointC: Qt.point(triOuter.pointC.x + (root.showBorder ? root.borderWidth : 0), triOuter.pointC.y + (root.showBorder ? (1 + Math.SQRT2) * root.borderWidth : 0))
        }
    }//shapeCtrl

    /* 内层画布：方向切换的旋转载体（root 不旋转——组件自身稳定，
       rotation 留给宿主；消费方不受方向变化影响）。旋转绕画布中心
       （= 三角形重心）——方向切换位置自动正确。 */
    Item {
        id: canvas
        anchors.fill: parent

        /* 方向 → 旋转角度（基准形 SW——尖朝左下 = 135° 标准角；旋转后
           尖朝标准角 D 需 rotation = D - 135，顺时针 45° 步进：
           SW=0/W=45/NW=90/N=135/NE=180/E=225/SE=270/S=315——
           E=225 即 135+225=360° 朝右、W=45 即 135+45=180° 朝左）。 */
        rotation: {
            switch (root.direction) {
            case Qore.SW:
                return 0;
            case Qore.W:
                return 45;
            case Qore.NW:
                return 90;
            case Qore.N:
                return 135;
            case Qore.NE:
                return 180;
            case Qore.E:
                return 225;
            case Qore.SE:
                return 270;
            case Qore.S:
                return 315;
            }
            return 0;
        }

        // 方向切换 = 旋转过渡（无点级动画——静态三角形）。
        // BasicRotationBehavior——沿最近路径旋转（如 NW→SW 走 90°
        // 而非 270°），动画到等价角后静默跳回目标值
        BasicRotationBehavior on rotation {
            enabled: root.animationEnabled
            duration: root.animationDuration
        }

    // 两个重叠 Shape（背景 = 边框层、前景 = 填充层）。无边框路径时背景
    // Shape 整体 visible: false——真不渲染（Shape 是 Item）
    Shape {
        anchors.fill: parent
        visible: root.showBorder && root.direction !== Qore.Unknown

        // 大三角形（边框层——borderColor 实心）
        ShapePath {
            startX: triOuter.pointA.x
            startY: triOuter.pointA.y
            PathLine {
                x: triOuter.pointB.x
                y: triOuter.pointB.y
            }
            PathLine {
                x: triOuter.pointC.x
                y: triOuter.pointC.y
            }
            PathLine {
                x: triOuter.pointA.x
                y: triOuter.pointA.y
            }
            // ShapePath 默认白色描边（strokeColor 默认 white/width 1）——
            // 必须显式禁用（叠放方案纯填充）：transparent + width 0
            fillColor: root.borderColor
            strokeColor: "transparent"
            strokeWidth: 0
        }
    }

    Shape {
        anchors.fill: parent
        visible: root.direction !== Qore.Unknown

        // 小三角形（填充层——fillColor 实心）。坐标绑定 triInner
        // （无边框路径时跳转绑 triOuter——满尺寸）；Behavior 挂坐标——
        // borderWidth 等动态变化经绑定重算后平滑过渡（不瞬跳）
        ShapePath {
            startX: (root.showBorder ? triInner : triOuter).pointA.x
            startY: (root.showBorder ? triInner : triOuter).pointA.y
            BasicNumberBehavior on startX {
                enabled: root.animationEnabled
                duration: root.animationDuration
            }
            BasicNumberBehavior on startY {
                enabled: root.animationEnabled
                duration: root.animationDuration
            }
            PathLine {
                x: (root.showBorder ? triInner : triOuter).pointB.x
                y: (root.showBorder ? triInner : triOuter).pointB.y
                BasicNumberBehavior on x {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
                BasicNumberBehavior on y {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
            }
            PathLine {
                x: (root.showBorder ? triInner : triOuter).pointC.x
                y: (root.showBorder ? triInner : triOuter).pointC.y
                BasicNumberBehavior on x {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
                BasicNumberBehavior on y {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
            }
            PathLine {
                x: (root.showBorder ? triInner : triOuter).pointA.x
                y: (root.showBorder ? triInner : triOuter).pointA.y
                BasicNumberBehavior on x {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
                BasicNumberBehavior on y {
                    enabled: root.animationEnabled
                    duration: root.animationDuration
                }
            }
            // ShapePath 默认白色描边——必须显式禁用（纯填充）
            fillColor: root.fillColor
            strokeColor: "transparent"
            strokeWidth: 0
        }
        }
    }//canvas

    /* 精确命中（默认）：QtObject 掩码（文档示例写法——QML 对象定义
       contains；QML Item 自身 function contains 不覆写 C++ 虚函数，
       引擎命中不走）。contains 收到 root 本地坐标；经 canvas.mapFromItem
       映射到画布本地（映射使用 item 变换——与视觉旋转严格一致），再
       CircleGadget 粗判 + TriangleGadget 精确三点判定。 */
    /* 命中（默认）：CircleGadget 直接作 containmentMask（QObject 且
       contains 为 Q_INVOKABLE——掩码接受 QObject*，无需 QtObject 包装）。
       仅内接圆判定（画布内切圆 s/2——旋转安全半径）。刻意简化：
       BasicArrow 主要用途是小尺寸箭头，精确三角形判定过度且无意义；
       圆判定宽松、旋转不变（中心/半径不随画布旋转变化——无需坐标变换，
       直接以 root 本地点判定）。 */
    containmentMask: circleG
}
